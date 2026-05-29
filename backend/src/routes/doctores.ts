import { Router, Response } from 'express';
import bcrypt from 'bcryptjs'; // Importamos bcrypt para encriptar la contraseña del nuevo doctor
import { prisma } from '../db';
import { AuthRequest, verificarToken } from '../middleware/auth';

const router = Router();

// ==========================================
// OBTENER TODOS LOS DOCTORES DE LA CLÍNICA
// ==========================================
router.get('/', verificarToken, async (req: AuthRequest, res: Response): Promise<any> => {
  try {
    const id_tenant = req.usuario.id_tenant;

    const doctores = await prisma.doctor.findMany({
      where: { 
        // Viajamos a través de la relación: Doctor -> Clínica -> Tenant
        clinica: {
          id_tenant: id_tenant
        }
      },
      include: {
        // Traemos los datos personales del doctor (nombre, apellido, correo)
        usuario: true,
        // Traemos el nombre de su especialidad
        especialidad: true,
        // Traemos los datos de la clínica a la que pertenece
        clinica: true,
        // Extraemos los horarios para alimentar el Dropdown de Flutter
        disponibilidad: true 
      }
    });

    // Como la contraseña viene incluida en "usuario", la filtramos por seguridad
    // antes de enviarla a la aplicación móvil
    const doctoresSeguros = doctores.map(doc => {
      const { password, ...usuarioSinPassword } = doc.usuario;
      return {
        ...doc,
        usuario: usuarioSinPassword
      };
    });

    res.json(doctoresSeguros);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener el catálogo de doctores' });
  }
});

// ==========================================
// REGISTRAR UN NUEVO MÉDICO (ADMIN)
// ==========================================
router.post('/', verificarToken, async (req: AuthRequest, res: Response): Promise<any> => {
  const { nombre, apellido, correo, password, id_especialidad } = req.body;
  const id_tenant = req.usuario.id_tenant;

  try {
    // 1. Buscar la clínica que le pertenece al tenant del administrador
    const clinica = await prisma.clinica.findFirst({
      where: { id_tenant: id_tenant }
    });

    if (!clinica) {
      return res.status(404).json({ error: 'No se encontró una clínica asignada a esta cuenta.' });
    }

    // 2. Verificar que el correo no esté duplicado en esta clínica
    const existeUsuario = await prisma.usuario.findUnique({
      where: { 
        id_tenant_correo: { id_tenant, correo } 
      }
    });

    if (existeUsuario) {
      return res.status(400).json({ error: 'El correo ya está registrado en esta clínica.' });
    }

    // 3. Encriptar la contraseña de acceso del médico
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 4. Guardar en Base de Datos usando una Transacción (Todo o Nada)
    const nuevoDoctor = await prisma.$transaction(async (tx) => {
      // a) Creamos el perfil de acceso
      const usuario = await tx.usuario.create({
        data: {
          id_tenant,
          nombre,
          apellido,
          correo,
          password: hashedPassword,
          tipo_usuario: 'doctor' // Asignamos el rol automáticamente
        }
      });

      // b) Creamos su perfil profesional asociado a su clínica y especialidad
      const doctor = await tx.doctor.create({
        data: {
          id_usuario: usuario.id_usuario,
          id_especialidad: Number(id_especialidad),
          id_clinica: clinica.id_clinica,
          numero_licencia: "PENDIENTE" // <-- ¡Aquí agregamos el campo faltante!
        },
        include: {
          usuario: {
            select: { nombre: true, apellido: true, correo: true } 
          },
          especialidad: true
        }
      });

      return doctor;
    });

    res.status(201).json({ 
      mensaje: 'Médico registrado exitosamente', 
      doctor: nuevoDoctor 
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error interno al registrar al médico.' });
  }
});

export default router;