import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart'; // Importamos main para poder regresar a la pantalla de Login

class DashboardMedicoScreen extends StatefulWidget {
  final String token;
  const DashboardMedicoScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<DashboardMedicoScreen> createState() => _DashboardMedicoScreenState();
}

class _DashboardMedicoScreenState extends State<DashboardMedicoScreen> {
  List<dynamic> _pacientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAgenda();
  }

  Future<void> _cargarAgenda() async {
    try {
      // OJO: Esta URL debe coincidir con la ruta de tu backend para las citas del doctor
      final res = await http.get(
        Uri.parse('http://127.0.0.1:3000/api/citas/agenda'), 
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _pacientes = jsonDecode(res.body);
            _cargando = false;
          });
        }
      } else {
        if (mounted) setState(() => _cargando = false);
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
      print('Error al cargar agenda: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Agenda Médica'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Cerrar sesión y volver al login
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (c) => const PantallaLoginResponsiva())
              );
            },
          )
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _pacientes.isEmpty
              ? _vistaSinCitas()
              : _vistaConCitas(),
    );
  }

  Widget _vistaSinCitas() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '¡Día libre, Doctor Carlos!',
            style: TextStyle(fontSize: 24, color: Colors.grey[600]),
          ),
          const Text('No tienes pacientes agendados por el momento.'),
        ],
      ),
    );
  }

  Widget _vistaConCitas() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pacientes.length,
      itemBuilder: (context, i) {
        final cita = _pacientes[i];
        // Aquí asumimos la estructura de tu JSON. Puede variar dependiendo de tu backend
        final paciente = cita['paciente']['usuario'];
        final motivo = cita['motivo'] ?? 'Revisión general';
        final fecha = cita['disponibilidad']['fecha'].toString().split('T')[0];
        final hora = cita['disponibilidad']['hora_inicio'].toString().substring(11, 16);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[900]),
            ),
            title: Text(
              'Paciente: ${paciente['nombre']} ${paciente['apellido']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Fecha: $fecha - $hora hrs\nMotivo: $motivo'),
            trailing: Chip(
              label: Text(
                cita['estado_cita'].toString().toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: Colors.orange,
            ),
          ),
        );
      },
    );
  }
}