# 🏥 Citas Salud SaaS

Plataforma integral multitenant para la gestión médica y agendamiento de citas. Diseñada con una arquitectura moderna de microservicios y despliegue por contenedores para garantizar alta disponibilidad y seguridad en entornos hospitalarios.

---

## 🏗️ Arquitectura del Sistema

El proyecto está dividido en dos capas principales que operan de forma desacoplada:

### 1. Backend (API RESTful)

El motor principal del sistema, encargado de procesar la lógica de negocio, autenticación, y gestión de la base de datos multitenant.

* **Entorno:** Node.js + Express.
* **ORM:** Prisma, utilizado para tipado estricto, migraciones seguras y consultas relacionales complejas.
* **Base de Datos:** MariaDB.
* **Seguridad:** * Encriptación de contraseñas de un solo sentido utilizando `bcryptjs`.
* Control de acceso basado en roles (RBAC) mediante tokens JWT (`jsonwebtoken`).


* **Estructura Multitenant:** Aislamiento lógico de datos. Cada petición y registro se asocia a un `id_tenant` (ID de Clínica) para garantizar que la información de distintos hospitales nunca se cruce.

### 2. Frontend (Aplicación Cliente)

Interfaz gráfica multiplataforma consumidora de la API.

* **Tecnología:** Flutter (Web / Mobile).
* **Enrutamiento Inteligente:** La interfaz gráfica es dinámica y responde al token JWT recibido, redirigiendo al usuario a su panel correspondiente:
* **Administrador:** Panel de métricas, KPIs y gestión de altas médicas.
* **Doctor:** Visualización de agenda interactiva y control de estado de citas.
* **Paciente:** Directorio médico y agendamiento de disponibilidad.

---

## 🚀 Guía de Instalación Universal

Gracias a la integración con Docker, el backend de este sistema es agnóstico al sistema operativo y a la arquitectura del hardware. Puedes desplegarlo en Windows, Linux, macOS o servidores ARM64 sin configurar dependencias locales.

### Requisitos Previos

1. [Docker](https://www.docker.com/) y Docker Compose instalados en la máquina host.
2. [Flutter SDK](https://docs.flutter.dev/get-started/install) (Solo si se desea compilar el frontend localmente).
3. [Node.js](https://nodejs.org/) (Opcional, solo para desarrollo local fuera de contenedores).

### Paso 1: Configurar Variables de Entorno

En la raíz de la carpeta `backend`, crea un archivo llamado `.env` y configura la cadena de conexión a la base de datos y la llave secreta para los tokens:

```env
DATABASE_URL="mysql://usuario:password@localhost:3306/sistema_medico"
JWT_SECRET="tu_super_llave_secreta_aqui"

```

*(Nota: Si despliegas con Docker, asegúrate de que el host `localhost` apunte al nombre del contenedor de la base de datos).*

### Paso 2: Despliegue del Backend y Base de Datos (Docker)

Para levantar la base de datos MariaDB y preparar el entorno sin instalar dependencias locales, ejecuta:

```bash
# 1. Navegar a la carpeta del backend
cd backend

# 2. Levantar los contenedores en segundo plano
docker-compose up -d

# 3. Generar el cliente de Prisma e impactar la base de datos
npx prisma generate
npx prisma db push

```

El servidor backend ahora estará corriendo y escuchando peticiones en el puerto `3000`.

### Paso 3: Ejecución del Frontend (Flutter Web)

Abre una nueva terminal, navega a la carpeta del frontend y levanta el servidor de desarrollo de Flutter:

```bash
# 1. Navegar a la carpeta del cliente
cd citas_salud_frontend

# 2. Descargar dependencias
flutter pub get

# 3. Correr la aplicación en el navegador Chrome
flutter run -d chrome

```

---

## 🔑 Credenciales de Prueba (Semilla de Datos)

Para evaluar el sistema recién instalado, utiliza las siguientes credenciales en el portal de inicio de sesión:

**1. Perfil Administrador (Dashboard y Gestión)**

* **ID Clínica:** `2`
* **Correo:** `laura.admin@sanangel.com`
* **Password:** `admin123`

**2. Perfil Médico (Agenda de Citas)**

* **ID Clínica:** `2`
* **Correo:** `carlos.mendoza@sanangel.com`
* **Password:** `doctor123`

---

*Sistema desarrollado como proyecto de ingeniería de software para despliegue en entornos clínicos reales.*