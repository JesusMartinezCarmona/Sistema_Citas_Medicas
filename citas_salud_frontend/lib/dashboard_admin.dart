import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart'; 

class DashboardAdminScreen extends StatefulWidget {
  final String token;
  const DashboardAdminScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  int _indiceActual = 0;
  
  // Variables para la lista de médicos
  List<dynamic> _doctores = [];
  bool _cargandoDoctores = true;

  @override
  void initState() {
    super.initState();
    _cargarDoctores();
  }

  // Petición al backend para traer la plantilla médica
  Future<void> _cargarDoctores() async {
    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:3000/api/doctores'),
        headers: {'Authorization': 'Bearer ${widget.token}'}
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _doctores = jsonDecode(res.body);
            _cargandoDoctores = false;
          });
        }
      } else {
        if (mounted) setState(() => _cargandoDoctores = false);
      }
    } catch (e) {
      print('Error al cargar doctores: $e');
      if (mounted) setState(() => _cargandoDoctores = false);
    }
  }

  // ==========================================
  // FORMULARIO: ALTA DE NUEVO MÉDICO
  // ==========================================
  void _mostrarDialogoNuevoDoctor() {
    final _nombreController = TextEditingController();
    final _apellidoController = TextEditingController();
    final _correoController = TextEditingController();
    final _passController = TextEditingController();
    String? _especialidadSeleccionada;

    // TODO: En el futuro esto vendrá de la Base de Datos. 
    // Por ahora ponemos unas de prueba para la interfaz gráfica.
    final List<Map<String, dynamic>> especialidades = [
      {'id': 1, 'nombre': 'Cardiología'},
      {'id': 2, 'nombre': 'Dermatología'},
      {'id': 3, 'nombre': 'Pediatría'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Nuevo Médico', style: TextStyle(color: Colors.blueGrey)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController, 
                decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline))
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apellidoController, 
                decoration: const InputDecoration(labelText: 'Apellido', prefixIcon: Icon(Icons.badge_outlined))
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _correoController, 
                decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email_outlined))
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passController, 
                obscureText: true, 
                decoration: const InputDecoration(labelText: 'Contraseña temporal', prefixIcon: Icon(Icons.lock_outline))
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Especialidad', border: OutlineInputBorder()),
                items: especialidades.map((e) => DropdownMenuItem(
                  value: e['id'].toString(), 
                  child: Text(e['nombre'].toString())
                )).toList(),
                onChanged: (val) {
                  _especialidadSeleccionada = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white),
            onPressed: () {
              // Aquí conectaremos con el backend más adelante
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Interfaz lista. Falta conectar con Node.js'))
              );
              Navigator.pop(context);
            },
            child: const Text('Guardar Médico'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> vistas = [
      _vistaReportes(),
      _vistaDoctores(),
      _vistaPacientes(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (c) => const PantallaLoginResponsiva())
              );
            },
          )
        ],
      ),
      body: vistas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        selectedItemColor: Colors.blueGrey[900],
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Médicos'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'),
        ],
      ),
    );
  }

  // ==========================================
  // HERRAMIENTA 1: REPORTES Y MÉTRICAS
  // ==========================================
  Widget _vistaReportes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de la Clínica', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _tarjetaKPI('Total Pacientes', '142', Icons.groups, Colors.blue),
              _tarjetaKPI('Médicos Activos', _doctores.length.toString(), Icons.medical_information, Colors.green),
              _tarjetaKPI('Citas Hoy', '28', Icons.calendar_today, Colors.orange),
              _tarjetaKPI('Ingresos Mes', '\$45,000', Icons.attach_money, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaKPI(String titulo, String valor, IconData icono, MaterialColor color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 32, color: color),
          const SizedBox(height: 12),
          Text(titulo, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // HERRAMIENTA 2: GESTIÓN DE MÉDICOS (AHORA DINÁMICA)
  // ==========================================
  Widget _vistaDoctores() {
    return Scaffold(
      body: _cargandoDoctores 
        ? const Center(child: CircularProgressIndicator())
        : _doctores.isEmpty
          ? const Center(child: Text('No hay médicos registrados en esta clínica.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _doctores.length,
              itemBuilder: (context, i) {
                final doc = _doctores[i];
                final u = doc['usuario'];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey[100],
                      child: const Icon(Icons.person, color: Colors.blueGrey),
                    ),
                    title: Text(
                      'Dr. ${u['nombre']} ${u['apellido']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Especialidad: ${doc['especialidad']['nombre']}\nCorreo: ${u['correo']}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                      onPressed: () {
                        // Futura acción: Editar datos del doctor
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoDoctor, // ¡Aquí se conecta la función de la ventana emergente!
        backgroundColor: Colors.blueGrey[900],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Doctor', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ==========================================
  // HERRAMIENTA 3: DIRECTORIO DE PACIENTES
  // ==========================================
  Widget _vistaPacientes() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Directorio de Pacientes', style: TextStyle(fontSize: 20, color: Colors.grey)),
          Text('Aquí mostraremos el historial y estatus de los pacientes'),
        ],
      ),
    );
  }
}