import { Router, Response } from 'express';
import { prisma } from '../db';
import { AuthRequest, verificarToken } from '../middleware/auth';

const router = Router();

// ==========================================
// AGENDAR UNA CITA NUEVA
// ==========================================
router.post('/', verificarToken, async (req: AuthRequest, res: Response): Promise<any> => {
  const { id_disponibilidad, motivo } = req.body;

  try {
    // 1. Buscar el id_paciente que le corresponde al id_usuario del token
    const paciente = await prisma.paciente.findUnique({
      where: { id_usuario: req.usuario.id_usuario }
    });

    if (!paciente) {
      return res.status(404).json({ error: 'El usuario autenticado no está registrado como paciente.' });
    }

    // 2. Obtener el id_doctor que ofrece este horario disponible
    const disponibilidad = await prisma.disponibilidad.findUnique({
      where: { id_disponibilidad: Number(id_disponibilidad) }
    });

    if (!disponibilidad) {
      return res.status(404).json({ error: 'El horario de disponibilidad seleccionado no existe.' });
    }

    // 3. Crear la cita con las columnas exactas de tu Base de Datos
    const nuevaCita = await prisma.cita.create({
      data: {
        id_paciente: paciente.id_paciente,
        id_doctor: disponibilidad.id_doctor,
        id_disponibilidad: disponibilidad.id_disponibilidad,
        motivo: motivo || null,
        estado: 'programada' // En minúsculas exactas como lo definiste en tu enum cita_estado
      }
    });

    res.status(201).json({ mensaje: 'Cita agendada exitosamente', cita: nuevaCita });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al intentar agendar la cita' });
  }
});

// ==========================================
// OBTENER MIS CITAS (PACIENTE)
// ==========================================
router.get('/mis-citas', verificarToken, async (req: AuthRequest, res: Response): Promise<any> => {
  try {
    const id_usuario = req.usuario.id_usuario;

    // 1. Validamos que el usuario tenga perfil de paciente
    const paciente = await prisma.paciente.findUnique({
      where: { id_usuario: id_usuario }
    });

    if (!paciente) {
      return res.status(403).json({ error: 'El usuario autenticado no está registrado como paciente.' });
    }

    // 2. Traemos las citas con toda la información anidada del doctor
    const citas = await prisma.cita.findMany({
      where: {
        id_paciente: paciente.id_paciente
      },
      orderBy: {
        id_cita: 'desc' // Para ver las citas más nuevas hasta arriba
      },
      include: {
        disponibilidad: {
          include: {
            doctor: {
              include: {
                // Traemos los datos personales del doctor (sin contraseñas)
                usuario: {
                  select: {
                    nombre: true,
                    apellido: true
                  }
                },
                // Traemos el nombre de la especialidad
                especialidad: true
              }
            }
          }
        }
      }
    });

    res.json(citas);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener el historial de citas' });
  }
});

// ==========================================
// OBTENER MI AGENDA (DOCTOR)
// ==========================================
router.get('/agenda', verificarToken, async (req: AuthRequest, res: Response): Promise<any> => {
  try {
    const id_usuario = req.usuario.id_usuario;

    // 1. Validamos que el usuario tenga perfil de doctor
    const doctor = await prisma.doctor.findUnique({
      where: { id_usuario: id_usuario }
    });

    if (!doctor) {
      return res.status(403).json({ error: 'El usuario autenticado no está registrado como doctor.' });
    }

    // 2. Traemos las citas con toda la información anidada del paciente
    const citas = await prisma.cita.findMany({
      where: {
        id_doctor: doctor.id_doctor
      },
      orderBy: {
        // Ordenamos para ver las citas más próximas/nuevas
        id_cita: 'desc' 
      },
      include: {
        // Traemos el horario
        disponibilidad: true,
        // Traemos los datos del paciente
        paciente: {
          include: {
            usuario: {
              select: {
                nombre: true,
                apellido: true,
                correo: true
              }
            }
          }
        }
      }
    });

    // 3. Adaptador para el Frontend (Cambiamos 'estado' a 'estado_cita' para que Flutter no falle)
    const agendaFormateada = citas.map(cita => ({
      ...cita,
      estado_cita: cita.estado 
    }));

    res.json(agendaFormateada);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener la agenda del doctor' });
  }
});
export default router;