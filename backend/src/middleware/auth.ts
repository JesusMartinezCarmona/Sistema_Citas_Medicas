import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

// Extendemos la interfaz de Express para decirle a TypeScript 
// que nuestras peticiones ahora tendrán una propiedad "usuario"
export interface AuthRequest extends Request {
  usuario?: any;
}

export const verificarToken = (req: AuthRequest, res: Response, next: NextFunction): any => {
  // 1. El token suele enviarse en una cabecera llamada "Authorization" con el formato "Bearer <token>"
  const authHeader = req.header('Authorization');
  const token = authHeader?.split(' ')[1]; 

  // 2. Si no trae gafete, lo rebotamos en la puerta
  if (!token) {
    return res.status(401).json({ error: 'Acceso denegado. No se proporcionó un token.' });
  }

  try {
    // 3. Verificamos que el token sea auténtico y no haya sido alterado
    const decodificado = jwt.verify(token, process.env.JWT_SECRET as string);
    
    // 4. Si es válido, guardamos la información de Carlos (id, tenant, rol) dentro de req.usuario
    req.usuario = decodificado;
    
    // 5. Le decimos al servidor "Todo en orden, déjalo pasar a la ruta que pidió"
    next(); 
  } catch (error) {
    return res.status(401).json({ error: 'Token inválido o expirado.' });
  }
};