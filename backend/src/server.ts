import 'dotenv/config'; // Carga las variables de entorno (.env)
import express, { Request, Response } from 'express';
import cors from 'cors';

// Importaciones de nuestros módulos
import { prisma } from './db';
import authRoutes from './routes/auth';
import doctoresRoutes from './routes/doctores'; // <-- ¡NUEVO! Importamos los doctores
import citasRoutes from './routes/citas';       // <-- ¡NUEVO! Importamos las citas
import { verificarToken, AuthRequest } from './middleware/auth';

// Inicializamos Express
const app = express();

// ==========================================
// MIDDLEWARES GLOBALES
// ==========================================
app.use(cors());
app.use(express.json());

// ==========================================
// RUTAS PÚBLICAS (No requieren Token)
// ==========================================
app.get('/', (req: Request, res: Response) => {
  res.send('¡Servidor del Sistema Médico SaaS funcionando al 100%!');
});

app.get('/api/tenants', async (req: Request, res: Response) => {
  try {
    const tenants = await prisma.tenant.findMany();
    res.json(tenants);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al conectar con la base de datos' });
  }
});

// ==========================================
// RUTAS DE AUTENTICACIÓN
// ==========================================
app.use('/api/auth', authRoutes);

// ==========================================
// RUTAS PROTEGIDAS (Requieren Token JWT)
// ==========================================
// Aquí es donde le enseñamos al servidor que las rutas existen
app.use('/api/doctores', doctoresRoutes); 
app.use('/api/citas', citasRoutes);       

// Ruta de prueba del perfil
app.get('/api/perfil', verificarToken, async (req: AuthRequest, res: Response) => {
  res.json({
    mensaje: '¡Bienvenido a la zona segura de la clínica!',
    tus_datos_secretos: req.usuario
  });
});

// ==========================================
// INICIAR EL SERVIDOR
// ==========================================
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});