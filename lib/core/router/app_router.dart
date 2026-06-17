import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/features/admin/presentation/superadmin_managers_screen.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'package:vive_core/features/home/presentation/public_landing_screen.dart';

// UTILS
import 'package:vive_core/core/widgets/error_view.dart'; // Asegúrate de importar ErrorView
import 'package:vive_core/core/router/go_router_refresh_stream.dart';
import 'package:vive_core/features/admin/presentation/admin_news_screen.dart';
import 'package:vive_core/features/admin/presentation/admin_user_screen.dart';
import 'package:vive_core/features/admin/presentation/admin_winner_check_screen.dart';
import 'package:vive_core/features/admin/presentation/screens/admin_sponsors_screen.dart';
import 'package:vive_core/features/admin/presentation/superadmin_cities_screen.dart';
import 'package:vive_core/features/admin/presentation/superadmin_city_from_screen.dart';

// PROVIDERS
import 'package:vive_core/features/auth/presentation/providers/auth_provider.dart';
import 'package:vive_core/features/auth/presentation/register_screen.dart';
import 'package:vive_core/features/auth/presentation/update_password_screen.dart';

// MODELOS
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';

// PANTALLAS MÓVIL (PÚBLICAS)
import 'package:vive_core/features/hub/presentation/hub_screen.dart';
import 'package:vive_core/features/home/presentation/event_shell_screen.dart';
import 'package:vive_core/features/home/presentation/home_screen.dart';
import 'package:vive_core/features/map/presentation/map_screen.dart';
import 'package:vive_core/features/scan/presentation/passport_screen.dart';
import 'package:vive_core/features/home/presentation/establishments_list_screen.dart';
import 'package:vive_core/features/home/presentation/tapas_list_screen.dart';
import 'package:vive_core/features/home/presentation/ranking_screen.dart';
import 'package:vive_core/features/home/presentation/establishment_detail_screen.dart';
import 'package:vive_core/features/scan/presentation/scan_qr_screen.dart';
import 'package:vive_core/features/auth/presentation/profile_screen.dart';
import 'package:vive_core/features/auth/presentation/login_screen.dart';
import 'package:vive_core/features/home/presentation/splash_screen.dart';

// PANTALLAS ADMIN (PRIVADAS)
import 'package:vive_core/features/admin/presentation/admin_shell_screen.dart';
import 'package:vive_core/features/admin/presentation/establishment_form_screen.dart';
import 'package:vive_core/features/admin/presentation/admin_establishments_screen.dart';
import 'package:vive_core/features/admin/presentation/admin_events_screen.dart';
import 'package:vive_core/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:vive_core/features/admin/presentation/admin_products_screen.dart';
import 'package:vive_core/features/admin/presentation/product_form_screen.dart';
import 'package:vive_core/features/admin/presentation/admin_establishment_detail_screen.dart';
import 'package:vive_core/features/admin/presentation/admin_product_detail_screen.dart';

// PANTALLAS ADMIN (PRIVADAS)
import 'package:vive_core/features/admin/presentation/superadmin_dashboard_screen.dart'; // <--- AÑADE ESTO

// PANTALLAS SUPERADMIN (PRIVADAS)
import 'package:vive_core/features/admin/presentation/superadmin_shell_screen.dart';
import 'package:vive_core/features/auth/presentation/b2b_login_screen.dart'; // <--- AÑADE ESTO

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);
  
  final authStream = Supabase.instance.client.auth.onAuthStateChange.where(
    (data) => data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),

    redirect: (context, state) async {
      final isLoggedIn = authState.valueOrNull != null;
      final isGoingToAdmin = state.uri.path.startsWith('/admin');
      final isGoingToSuperadmin = state.uri.path.startsWith('/superadmin');
      final isGoingToLogin = state.uri.path == '/login';
      final isGoingToRecovery = state.uri.path == '/update-password';
      final isGoingToRoot = state.uri.path == '/';
      final isGoingToWorkspace = state.uri.path == '/workspace'; // <--- Nueva variable
      
      // Lógica de subdominio (para el futuro en producción)
      final isB2BDomain = state.uri.host.startsWith('admin.');

      // 1. Siempre permitimos ir a recuperar contraseña
      if(isGoingToRecovery) return null;

      // 2. 🛡️ CONTROL B2B: Forzar pantalla aséptica si es necesario
      if (!isLoggedIn) {
        // Si no está logueado y va al subdominio admin, o teclea /workspace, o intenta forzar una URL privada
        if (isB2BDomain || isGoingToWorkspace || isGoingToAdmin || isGoingToSuperadmin) {
           return '/workspace'; // Al login corporativo
        }
      }

      // 3. 🛡️ VERIFICACIÓN DE ROLES (Para los que ya han hecho login y quieren entrar a zonas privadas)
      if (isLoggedIn && (isGoingToAdmin || isGoingToSuperadmin)) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          final role = profile?['role'] ?? 'user';
          
          if (isGoingToSuperadmin && role != 'superadmin') return '/';
          if (isGoingToAdmin && role != 'admin' && role != 'superadmin') return '/'; 
        }
      }
      
      // 4. 🔀 REDIRECCIÓN POST-LOGIN INTELIGENTE
      // Si el usuario ya está logueado e intenta ir a un login o al root
      if (isLoggedIn && (isGoingToLogin || isGoingToRoot || isGoingToWorkspace)) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();

          final role = profile?['role'] ?? 'user';
          
          // Los mandamos a su sitio correspondiente
          if (role == 'superadmin' && !isGoingToSuperadmin) return '/superadmin';
          if (role == 'admin' && !isGoingToAdmin) return '/admin';
          
          // Si es turista y estaba intentando ir a un login (B2B o normal), lo mandamos al Hub pacíficamente
          if (role == 'user' && (isGoingToLogin || isGoingToWorkspace)) return '/';
        }
      }

      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/update-password', builder: (context, state) => const UpdatePasswordScreen()),
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      // 🌐 RUTA RAÍZ DINÁMICA
      GoRoute(
        path: '/', 
        builder: (context, state) {
          final isLoggedIn = authState.valueOrNull != null;
          
          // Si está logueado (turista), va directo al Hub.
          // Si es un visitante anónimo, ve la Landing pública de "Vive Experiencias".
          return isLoggedIn ? const HubScreen(cityId: 1) : const PublicLandingScreen();
        },
      ),
      // Ruta del Hub Multi-Inquilino
      GoRoute(
        path: '/city/:cityId',
        builder: (context, state) {
          // Extraemos el ID de la URL
          final cityIdString = state.pathParameters['cityId'] ?? '1';
          final cityId = int.tryParse(cityIdString) ?? 1;

          // 🔥 MAGIA: Sincronizamos el Provider global ANTES de pintar la pantalla
          // Usamos microtask para no dar error de "setState() during build"
          Future.microtask(() {
            if (ref.read(currentCityIdProvider) != cityId) {
              ref.read(currentCityIdProvider.notifier).state = cityId;
            }
          });

          // Le pasamos el ID de la ciudad al HubScreen
          return HubScreen(cityId: cityId);
        },
      ),

      GoRoute(path: '/workspace', builder: (context, state) => const B2bLoginScreen()), // <--- AÑADE ESTA RUTA AQUÍ

      GoRoute(
        path: '/event/:id',
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          if (state.uri.path == '/event/$id') return '/event/$id/dashboard';
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              final eventId = state.pathParameters['id'] ?? '1';
              return EventShellScreen(
                navigationShell: navigationShell,
                eventId: eventId,
              );
            },
            branches: [
              StatefulShellBranch(routes: [GoRoute(path: 'dashboard', builder: (_, _) => const HomeScreen())]),
              StatefulShellBranch(routes: [GoRoute(path: 'map', builder: (_, _) => const MapScreen())]),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'locales',
                    builder: (context, state) {
                      final idString = state.pathParameters['eventId'];
                      final eventId = int.tryParse(idString ?? '') ?? 1;
                      return EstablishmentsListScreen(eventId: eventId);
                    },
                  ),
                ],
              ),
              StatefulShellBranch(routes: [GoRoute(path: 'tapas', builder: (_, _) => const TapasListScreen())]),
              StatefulShellBranch(routes: [GoRoute(path: 'ranking', builder: (_, _) => const RankingScreen())]),
              StatefulShellBranch(routes: [GoRoute(path: 'passport', builder: (_, _) => const PassportScreen())]),
            ],
          ),
        ],
      ),

      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/profile',
        builder: (context, state) {
          if (authState.valueOrNull == null) return const LoginScreen();
          final int? eventId = state.extra as int?;
          return ProfileScreen(eventId: eventId);
        },
      ),

      // 🛡️ DETAIL: PROTEGIDO (Tu código original)
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          final extra = state.extra;
          EstablishmentModel establishment;

          if (extra is EstablishmentModel) {
            establishment = extra;
          } else if (extra is Map) { // Usamos 'is Map' general
            // .from asegura que el cast sea correcto
            establishment = EstablishmentModel.fromJson(Map<String, dynamic>.from(extra));
          } else {
            return const Scaffold(body: Center(child: Text("Error al cargar datos del local")));
          }

          return EstablishmentDetailScreen(establishment: establishment);
        },
      ),

      // 🔥 SCAN: PROTEGIDO (NUEVO FIX)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/scan',
        builder: (context, state) {
          final extra = state.extra;
          EstablishmentModel establishment;

          // Aquí aplicamos la misma lógica robusta que en /detail
          if (extra is EstablishmentModel) {
            establishment = extra;
          } else if (extra is Map) {
            establishment = EstablishmentModel.fromJson(Map<String, dynamic>.from(extra));
          } else {
            // Si el usuario recarga la página /scan directamente sin datos, 
            // le mandamos un error o al inicio.
            return const ErrorView(error: "Datos del escáner no encontrados. Vuelve al listado.");
          }

          return ScanQrScreen(establishment: establishment);
        },
      ),

      // =====================================================================
      // 👑 ZONA SUPERADMIN (MODO CASI ROOT)
      // =====================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            SuperadminShellScreen(navigationShell: navigationShell),
        branches: [
          // RAMA 0: Dashboard Global
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/superadmin',
                builder: (_, _) => const SuperadminDashboardScreen(),
              ),
            ],
          ),
          // RAMA 1: Gestión de Franquicias
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/superadmin/cities',
                builder: (_, _) => const SuperadminCitiesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      // Extraemos los datos si venimos del botón "Editar"
                      final cityData = state.extra as Map<String, dynamic>?;
                      return SuperadminCityFormScreen(cityToEdit: cityData);
                    },
                  ),
                ],
              ),
            ],
          ),
          // RAMA 2: Gestión de Gestores
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/superadmin/managers',
                builder: (_, _) => const SuperadminManagersScreen(),
              ),
            ],
          ),
        ],
      ),

      // =====================================================================
      // 🛠️ ZONA ADMIN
      // =====================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (_, _) => const AdminDashboardScreen(),
                routes: [
                  GoRoute(path: 'sponsors', builder: (context, state) => const AdminSponsorsScreen()),
                  GoRoute(path: 'news', builder: (context, state) => const AdminNewsScreen()),
                  GoRoute(path: 'check-winner', builder: (context, state) => const AdminWinnerCheckScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/socios',
                builder: (_, _) => const AdminEstablishmentsScreen(),
                routes: [
                  GoRoute(path: 'nuevo', builder: (_, _) => const EstablishmentFormScreen()),
                  
                  // PROTEGIDO TAMBIÉN EN ADMIN POR SI ACASO
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      EstablishmentModel establishment;
                      if (extra is EstablishmentModel) {
                        establishment = extra;
                      } else if (extra is Map) {
                        establishment = EstablishmentModel.fromJson(Map<String, dynamic>.from(extra));
                      } else {
                        return const ErrorView(error: "Error cargando detalle admin");
                      }
                      return AdminEstablishmentDetailScreen(establishment: establishment);
                    },
                  ),
                  
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final extra = state.extra;
                      EstablishmentModel establishment;
                      if (extra is EstablishmentModel) {
                        establishment = extra;
                      } else if (extra is Map) {
                        establishment = EstablishmentModel.fromJson(Map<String, dynamic>.from(extra));
                      } else {
                        return const ErrorView(error: "Error cargando edición");
                      }
                      return EstablishmentFormScreen(establishmentToEdit: establishment);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/events', builder: (_, _) => const AdminEventsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/products',
                builder: (_, _) => const AdminProductsScreen(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    name: 'product_form',
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>?;
                      final eventId = args?['eventId'] as int? ?? 0;
                      // El productToEdit ya viene dentro del mapa, no hay problema de casting directo aquí
                      // porque 'args' ya se trata como mapa.
                      final product = args?['productToEdit'] as ProductModel?;
                      return ProductFormScreen(
                        initialEventId: eventId,
                        productToEdit: product,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      // Protección básica también para productos
                      final extra = state.extra;
                      ProductModel product;
                      if (extra is ProductModel) {
                        product = extra;
                      } else if (extra is Map) {
                        product = ProductModel.fromJson(Map<String, dynamic>.from(extra));
                      } else {
                         return const ErrorView(error: "Error cargando producto");
                      }
                      return AdminProductDetailScreen(product: product);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/users', builder: (_, _) => const AdminUsersScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}