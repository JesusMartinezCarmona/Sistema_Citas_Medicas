# 🗄️ Arquitectura de Base de Datos - Citas Salud SaaS

Este documento detalla la estructura, el diseño y las instrucciones de despliegue de la base de datos relacional que soporta la plataforma Citas Salud SaaS.

---

## 🛠️ Stack Tecnológico
* **Motor de Base de Datos:** MariaDB (Desplegado vía Docker, compatible con x86_64 y ARM64).
* **ORM (Object-Relational Mapping):** Prisma.
* **Paradigma:** Relacional (SQL) con arquitectura Multi-Tenant.

Se eligió **Prisma** como ORM debido a su tipado estricto (Type-Safe) con TypeScript, lo que previene errores en tiempo de ejecución, facilita la lectura del código y maneja las migraciones estructurales de forma segura mediante el archivo `schema.prisma`.

---

## 🚀 Instalación y Puesta en Marcha

El motor de base de datos está completamente dockerizado para asegurar consistencia entre el entorno de desarrollo y el servidor de producción (ya sea una máquina virtual o una placa embebida).

### 1. Requisitos Previos
* Tener instalado [Docker](https://docs.docker.com/get-docker/) y Docker Compose.
* No es necesario tener MariaDB instalado localmente en el sistema operativo host.

### 2. Configuración del Entorno (.env)
Asegúrate de tener tu archivo `.env` en la raíz del backend con la variable `DATABASE_URL` apuntando al contenedor.
```env
# Formato: mysql://USUARIO:PASSWORD@HOST:PUERTO/NOMBRE_BD
DATABASE_URL="mysql://root:rootpassword@localhost:3306/sistema_medico"

```

*(Nota: Cambia `localhost` por el nombre del servicio del contenedor si el backend también corre en Docker).*

### 3. Levantar el Contenedor

El archivo `docker-compose.yml` ya tiene definida la imagen oficial de MariaDB. Para iniciar la base de datos, ejecuta el siguiente comando en la terminal:

```bash
docker-compose up -d db

```

Este comando descargará la imagen correcta según la arquitectura de tu procesador y dejará la base de datos corriendo en segundo plano en el puerto `3306`.

### 4. Sincronizar la Estructura (Prisma)

Una vez que el contenedor de MariaDB esté corriendo, necesitas empujar la estructura de tus tablas (definidas en `schema.prisma`) hacia la base de datos vacía:

```bash
# Genera el cliente tipado para Node.js
npx prisma generate

# Crea las tablas en la base de datos
npx prisma db push

```

---

## 🏢 Arquitectura Multi-Tenant (Multi-Inquilino)

El sistema está diseñado para operar como un Software as a Service (SaaS), lo que significa que una sola instancia de la base de datos y la aplicación sirve a múltiples hospitales o clínicas simultáneamente.

* **Aislamiento de Datos:** Esto se logra a través de la llave foránea `id_tenant`. Prácticamente todas las transacciones y registros principales están vinculados a una `Clinica` específica.
* **Seguridad:** En el backend, las consultas validan el `id_tenant` extraído del token JWT del usuario, garantizando que un médico o administrador de la "Clínica A" jamás pueda consultar o modificar los registros de la "Clínica B".

---

## 🧩 Entidades Principales y Relaciones

La base de datos está normalizada para evitar redundancia y garantizar la integridad referencial. A continuación, se describen los modelos principales:

### 1. Sistema de Control de Acceso

* **`Clinica` (Tenant):** Entidad raíz. Representa a una organización médica. Contiene su nombre, dirección y configuración básica. Su `id_tenant` se hereda a las demás tablas.
* **`Usuario`:** Tabla central de autenticación. Almacena las credenciales de acceso (correo, contraseña encriptada) y los datos personales básicos.
* Utiliza el campo `tipo_usuario` (Enum: `admin`, `doctor`, `paciente`) para el Control de Acceso Basado en Roles (RBAC).
* La llave compuesta por `[id_tenant, correo]` asegura que no haya correos duplicados dentro de la misma clínica.



### 2. Perfiles Especializados

* **`Doctor`:** Contiene la información profesional del médico (ej. número de licencia) y se enlaza con su `Especialidad`.
* **`Paciente`:** Contiene la información clínica e historial del usuario que recibe la atención.
* **`Especialidad`:** Catálogo de ramas médicas asignables a los doctores de la clínica.

### 3. Motor de Agendamiento

* **`Disponibilidad`:** Define los bloques de tiempo que un `Doctor` abre en su agenda para recibir consultas.
* **`Cita`:** Tabla transaccional que registra el evento donde un `Paciente` reserva una `Disponibilidad` de un `Doctor`.

---

## 🔒 Seguridad e Integridad de Datos

* **Encriptación de Contraseñas:** Ninguna contraseña se guarda en texto plano. Se utiliza el algoritmo `bcryptjs`.
* **Transacciones Seguras (ACID):** Operaciones críticas se ejecutan utilizando el método `$transaction` de Prisma para asegurar el principio de "Todo o Nada".
* **Eliminación en Cascada (Cascade Delete):** Las llaves foráneas están configuradas para mantener la limpieza de la base de datos sin dejar registros huérfanos.

---

## 💻 Administración y Visualización

Para interactuar con los datos directamente, puedes utilizar la herramienta visual de Prisma integrada. En una nueva terminal, ejecuta:

```bash
npx prisma studio

```

Esto abrirá un panel de administración en tu navegador (usualmente en `http://localhost:5555`) donde podrás ver, editar y eliminar registros de las tablas de MariaDB de forma gráfica.

```

```