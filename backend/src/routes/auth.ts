import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../db';

const router = Router();

// ==========================================
// REGISTRO DE USUARIO
// ==========================================
router.post('/register', async (req: Request, res: Response): Promise<any> => {
  const { id_tenant, nombre, apellido, correo, password, tipo_usuario } = req.body;

  try {
    // 1. Verificar si el correo ya existe en ese tenant
    const usuarioExistente = await prisma.usuario.findUnique({
      where: {
        id_tenant_correo: { id_tenant, correo }
      }
    });

    if (usuarioExistente) {
      return res.status(400).json({ error: 'El correo ya está registrado en esta clínica' });
    }

    // 2. Encriptar la contraseña (Hashing)
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 3. Guardar en la base de datos
    const nuevoUsuario = await prisma.usuario.create({
      data: {
        id_tenant,
        nombre,
        apellido,
        correo,
        password: hashedPassword,
        tipo_usuario
      }
    });

    res.status(201).json({ mensaje: 'Usuario creado exitosamente', usuario: nuevoUsuario.correo });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al registrar el usuario' });
  }
});

// ==========================================
// INICIO DE SESIÓN (LOGIN)
// ==========================================
router.post('/login', async (req: Request, res: Response): Promise<any> => {
  const { id_tenant, correo, password } = req.body;

  try {
    // 1. Buscar al usuario
    const usuario = await prisma.usuario.findUnique({
      where: {
        id_tenant_correo: { id_tenant, correo }
      }
    });

    if (!usuario) {
      return res.status(404).json({ error: 'Credenciales inválidas' });
    }

    // 2. Comparar contraseñas
    const passwordValido = await bcrypt.compare(password, usuario.password);
    if (!passwordValido) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    // 3. Crear el Token JWT (El "pase VIP")
    const token = jwt.sign(
      { 
        id_usuario: usuario.id_usuario, 
        id_tenant: usuario.id_tenant, 
        rol: usuario.tipo_usuario 
      },
      process.env.JWT_SECRET as string,
      { expiresIn: '24h' }
    );

    res.json({ 
  mensaje: 'Login exitoso', 
  token,
  usuario: {
    id: usuario.id_usuario,
    rol: usuario.tipo_usuario
  }
});
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al iniciar sesión' });
  }
});

export default router;