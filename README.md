# Vive Experiencias - Plataforma B2B SaaS Gastronómica y Turística 🚀

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![FastAPI](https://img.shields.io/badge/FastAPI-Python-009688?logo=fastapi)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![Docker](https://img.shields.io/badge/Docker-Self%20Hosted-2496ED?logo=docker)

**Vive Experiencias** es una solución de software integral multiplataforma diseñada para la gestión, promoción y dinamización de eventos turísticos y gastronómicos (Rutas de la Tapa, Festivales, etc.) mediante un modelo multi-franquicia (B2B). 

Este proyecto ha sido desarrollado como Trabajo de Fin de Ciclo (TFG) para el Grado Superior en Desarrollo de Aplicaciones Multiplataforma (DAM).

## 🌟 Arquitectura del Sistema

El sistema opera bajo una arquitectura separada orientada a servicios:

* **Frontend (Flutter):**
    * **App Móvil (Android/iOS):** Para el usuario final (turista/ciudadano). Permite geolocalización de locales, escaneo de códigos QR para votaciones y visualización de rankings en tiempo real.
    * **Landing Page Pública:** Web responsiva para descarga del APK y selección de ciudad.
    * **Panel de Administración (Web):** Interfaz B2B para que gestores de ayuntamientos y franquicias administren sus eventos, productos y estadísticas B2B.
    * **Panel Superadmin:** Control global de la plataforma, creación de clientes, asignación de cuentas y visualización de métricas de alto nivel.
* **Backend (Python/FastAPI):** Motor de reglas de negocio aplicando los principios de *Clean Architecture*. Procesa las peticiones administrativas y actúa como puente seguro.
* **Base de Datos & Auth (Supabase):** Gestión de usuarios, políticas RLS (Row Level Security) y persistencia de datos en PostgreSQL.
* **Despliegue e Infraestructura:** Self-hosted mediante contenedores Docker y Nginx, securizado tras túneles de Cloudflare Zero Trust.

## 🛠️ Tecnologías Empleadas

* **UI/UX:** Flutter, Riverpod (Gestión de estado), GoRouter, Google Maps / OpenStreetMap.
* **Almacenamiento Local:** Hive (Base de datos NoSQL offline-first), SharedPreferences.
* **Seguridad:** Autenticación JWT, Cloudflare Tunnels (No Happy Eyeballs).

## 🚀 Despliegue en Producción

La aplicación se encuentra dockerizada y desplegada para su acceso global:
* **Web Portal:** [https://vivexperiencias.7finn.es](https://vivexperiencias.7finn.es)
* **Descarga APK:** Disponible en el menú de navegación de la plataforma web.

---
*Desarrollado con pasión y arquitectura limpia.*
