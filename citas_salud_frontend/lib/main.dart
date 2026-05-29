import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_medico.dart';
import 'dashboard_admin.dart'; // Importación vital para que funcione el rol admin

void main() {
  runApp(const CitasSaludApp());
}

class CitasSaludApp extends StatelessWidget {
  const CitasSaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citas Salud SaaS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[900]!),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const PantallaLoginResponsiva(),
    );
  }
}

// ==========================================
// VISTA DE LOGIN (RESPONSIVA)
// ==========================================
class PantallaLoginResponsiva extends StatelessWidget {
  const PantallaLoginResponsiva({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _vistaEscritorio();
          } else {
            return _vistaMovil();
          }
        },
      ),
    );
  }

  Widget _vistaEscritorio() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.blue[900],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital, size: 100, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Citas Salud SaaS',
                  style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Transformación Digital Médica',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              child: const FormularioLogin(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vistaMovil() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.local_hospital, size: 80, color: Colors.blue[900]),
            const SizedBox(height: 30),
            const FormularioLogin(),
          ],
        ),
      ),
    );
  }
}

class FormularioLogin extends StatefulWidget {
  const FormularioLogin({super.key});

  @override
  State<FormularioLogin> createState() => _FormularioLoginState();
}

class _FormularioLoginState extends State<FormularioLogin> {
  final _tenantController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _cargando = false;

  Future<void> _login() async {
    setState(() => _cargando = true);
    
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:3000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_tenant': int.tryParse(_tenantController.text) ?? 0,
          'correo': _emailController.text.trim(),
          'password': _passController.text,
        }),
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        
        // Extraemos el rol y el token que mandó el backend
        final String rol = data['usuario']['rol'];
        final String token = data['token'];

        if (mounted) {
          // ENRUTAMIENTO CONDICIONAL ESTRICTO
          if (rol == 'doctor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardMedicoScreen(token: token)),
            );
          } else if (rol == 'paciente') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PantallaInicio(token: token)),
            );
          } else if (rol == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardAdminScreen(token: token)),
            );
          } else {
            // Por seguridad, si llega un rol raro o nulo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Rol desconocido: $rol')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credenciales inválidas o Error en Servidor')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Bienvenido al Portal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        TextField(
          controller: _tenantController,
          decoration: const InputDecoration(labelText: 'ID Clínica (Tenant)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
            onPressed: _cargando ? null : _login,
            child: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Iniciar Sesión'),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL (TAB VIEW)
// ==========================================
class PantallaInicio extends StatefulWidget {
  final String token;
  const PantallaInicio({super.key, required this.token});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  List<dynamic> _doctores = [];
  List<dynamic> _citas = [];
  bool _cargandoDoc = true;
  bool _cargandoCit = true;

  @override
  void initState() {
    super.initState();
    _cargarDoctores();
    _cargarCitas();
  }

  Future<void> _cargarDoctores() async {
    final res = await http.get(Uri.parse('http://127.0.0.1:3000/api/doctores'),
        headers: {'Authorization': 'Bearer ${widget.token}'});
    if (res.statusCode == 200) {
      setState(() {
        _doctores = jsonDecode(res.body);
        _cargandoDoc = false;
      });
    }
  }

  Future<void> _cargarCitas() async {
    final res = await http.get(Uri.parse('http://127.0.0.1:3000/api/citas/mis-citas'),
        headers: {'Authorization': 'Bearer ${widget.token}'});
    if (res.statusCode == 200) {
      setState(() {
        _citas = jsonDecode(res.body);
        _cargandoCit = false;
      });
    }
  }

  Future<void> _agendarCita(String idDisp, String motivo) async {
    final res = await http.post(
      Uri.parse('http://127.0.0.1:3000/api/citas'),
      headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      body: jsonEncode({'id_disponibilidad': int.parse(idDisp), 'motivo': motivo}),
    );

    if (res.statusCode == 201) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita agendada'), backgroundColor: Colors.green));
        _cargarCitas();
      }
    }
  }

  void _dialogoNuevaCita(Map<String, dynamic> doctor) {
    final usuario = doctor['usuario'];
    final List<dynamic> horarios = doctor['disponibilidad'] ?? doctor['disponibilidades'] ?? [];
    String? _seleccion;
    final _motivo = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => AlertDialog(
          title: Text('Agendar con Dr. ${usuario['nombre']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (horarios.isEmpty)
                const Text('Sin horarios disponibles', style: TextStyle(color: Colors.red))
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Selecciona Horario', border: OutlineInputBorder()),
                  value: _seleccion,
                  items: horarios.map((h) {
                    final fecha = h['fecha'].toString().split('T')[0];
                    final rawInicio = h['hora_inicio'].toString();
                    final inicioLimpio = rawInicio.contains('T') ? rawInicio.split('T')[1].substring(0, 5) : rawInicio.substring(0, 5);
                    final rawFin = h['hora_fin'].toString();
                    final finLimpio = rawFin.contains('T') ? rawFin.split('T')[1].substring(0, 5) : rawFin.substring(0, 5);

                    return DropdownMenuItem(
                      value: h['id_disponibilidad'].toString(), 
                      child: Text('$fecha ($inicioLimpio - $finLimpio hrs)'), 
                    );
                  }).toList(),
                  onChanged: (val) => setPopupState(() => _seleccion = val),
                ),
              const SizedBox(height: 16),
              TextField(controller: _motivo, decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ElevatedButton(
              onPressed: _seleccion == null ? null : () => _agendarCita(_seleccion!, _motivo.text),
              child: const Text('Confirmar'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          title: const Text('Directorio Médico - Santa Elena'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            tabs: [Tab(icon: Icon(Icons.person_search), text: 'Médicos'), Tab(icon: Icon(Icons.event_note), text: 'Mis Citas')],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const PantallaLoginResponsiva())))
          ],
        ),
        body: TabBarView(
          children: [_tabDoctores(), _tabMisCitas()],
        ),
      ),
    );
  }

  Widget _tabDoctores() {
    if (_cargandoDoc) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 400, mainAxisExtent: 180, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: _doctores.length,
        itemBuilder: (context, i) {
          final doc = _doctores[i];
          final u = doc['usuario'];
          return Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. ${u['nombre']} ${u['apellido']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(doc['especialidad']['nombre'], style: TextStyle(color: Colors.blue[800])),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.green,
                      onPressed: () => _dialogoNuevaCita(doc),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tabMisCitas() {
    if (_cargandoCit) return const Center(child: CircularProgressIndicator());
    if (_citas.isEmpty) return const Center(child: Text('Aún no tienes citas agendadas.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _citas.length,
      itemBuilder: (context, i) {
        final cita = _citas[i];
        final disp = cita['disponibilidad'] ?? {};
        final docU = disp['doctor']['usuario'];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text('Dr. ${docU['nombre']} ${docU['apellido']}'),
            subtitle: Text('Motivo: ${cita['motivo']}\nFecha: ${disp['fecha'].toString().split('T')[0]}'),
            trailing: Text(cita['estado_cita'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        );
      },
    );
  }
}