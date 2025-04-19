import 'package:flutter/material.dart';
import 'package:jorge/gravador_view.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// MODELOS
class Cliente {
  final int? id;
  final String nome;
  final double saldoFiado;

  Cliente({this.id, required this.nome, this.saldoFiado = 0});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': nome, 'saldoFiado': saldoFiado};
  }
}

class Venda {
  final int? id;
  final int clienteId;
  final double valor;
  final bool fiado;

  Venda({this.id, required this.clienteId, required this.valor, required this.fiado});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'valor': valor,
      'fiado': fiado ? 1 : 0,
    };
  }
}

class Gasto {
  final int? id;
  final String descricao;
  final double valor;

  Gasto({this.id, required this.descricao, required this.valor});

  Map<String, dynamic> toMap() {
    return {'id': id, 'descricao': descricao, 'valor': valor};
  }
}

// BANCO DE DADOS
class DBHelper {
  static Future<Database> _openDB() async {
    return openDatabase(
      join(await getDatabasesPath(), 'padaria.db'),
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE clientes(id INTEGER PRIMARY KEY, nome TEXT, saldoFiado REAL)');
        await db.execute('CREATE TABLE vendas(id INTEGER PRIMARY KEY, clienteId INTEGER, valor REAL, fiado INTEGER)');
        await db.execute('CREATE TABLE gastos(id INTEGER PRIMARY KEY, descricao TEXT, valor REAL)');
      },
      version: 1,
    );
  }

  static Future<void> insertCliente(Cliente c) async {
    final db = await _openDB();
    await db.insert('clientes', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Cliente>> getClientes() async {
    final db = await _openDB();
    final maps = await db.query('clientes');
    return List.generate(maps.length, (i) {
      return Cliente(
        id: maps[i]['id'] as int,
        nome: maps[i]['nome'] as String,
        saldoFiado: maps[i]['saldoFiado'] as double,
      );
    });
  }

  static Future<void> deleteCliente(int id) async {
    final db = await _openDB();
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertVenda(Venda v) async {
    final db = await _openDB();
    await db.insert('vendas', v.toMap());
    if (v.fiado) {
      await db.rawUpdate('UPDATE clientes SET saldoFiado = saldoFiado + ? WHERE id = ?', [v.valor, v.clienteId]);
    }
  }

  static Future<List<Venda>> getVendas() async {
    final db = await _openDB();
    final maps = await db.query('vendas');
    return List.generate(maps.length, (i) {
      return Venda(
        id: maps[i]['id'] as int? ?? 0,
        clienteId: maps[i]['clienteId'] as int,
        valor: maps[i]['valor'] as double,
        fiado: maps[i]['fiado'] == 1,
      );
    });
  }

  static Future<void> deleteVenda(int id) async {
    final db = await _openDB();
    await db.delete('vendas', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertGasto(Gasto g) async {
    final db = await _openDB();
    await db.insert('gastos', g.toMap());
  }

  static Future<List<Gasto>> getGastos() async {
    final db = await _openDB();
    final maps = await db.query('gastos');
    return List.generate(maps.length, (i) {
      return Gasto(
        id: maps[i]['id'] as int? ?? 0,
        descricao: maps[i]['descricao'] as String,
        valor: maps[i]['valor'] as double,
      );
    });
  }

  static Future<void> deleteGasto(int id) async {
    final db = await _openDB();
    await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<double> getTotalVendas() async {
    final db = await _openDB();
    final result = await db.rawQuery('SELECT SUM(valor) as total FROM vendas WHERE fiado = 0');
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  static Future<double> getTotalGastos() async {
    final db = await _openDB();
    final result = await db.rawQuery('SELECT SUM(valor) as total FROM gastos');
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }

  static Future<double> getTotalFiado() async {
    final db = await _openDB();
    final result = await db.rawQuery('SELECT SUM(saldoFiado) as total FROM clientes');
    return result.first['total'] != null ? result.first['total'] as double : 0;
  }
}

// APP PRINCIPAL
void main() {
  runApp(const PadariaApp());
}

class PadariaApp extends StatelessWidget {
  const PadariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padaria do Jorgin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        brightness: Brightness.light,
      ),
      home: const HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// HOME
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('Padaria Nova Esperança', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _cardButton(context, 'Clientes', Icons.people_alt_rounded, const ClientesView()),
                _cardButton(context, 'Vendas', Icons.shopping_bag_rounded, const VendasView()),
                _cardButton(context, 'Gastos', Icons.money_off_rounded, const GastosView()),
                _cardButton(context, 'Relatório', Icons.bar_chart_rounded, const RelatorioView()),
                _cardButton(context, 'Gravar Voz', Icons.mic, const GravadorView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardButton(BuildContext context, String label, IconData icon, Widget tela) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tela)),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.brown.shade400),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TELA DE CLIENTES
class ClientesView extends StatelessWidget {
  const ClientesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: FutureBuilder<List<Cliente>>(
        future: DBHelper.getClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum cliente registrado.'));
          }

          final clientes = snapshot.data!;

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return ListTile(
                title: Text(cliente.nome),
                subtitle: Text('Saldo fiado: R\$ ${cliente.saldoFiado.toStringAsFixed(2)}'),
                onTap: () {
                  _showClienteForm(context, cliente);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    DBHelper.deleteCliente(cliente.id!);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClienteForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showClienteForm(BuildContext context, [Cliente? cliente]) {
    final nomeController = TextEditingController(text: cliente?.nome);
    final saldoController = TextEditingController(text: cliente?.saldoFiado.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(cliente == null ? 'Adicionar Cliente' : 'Editar Cliente'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: saldoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Saldo Fiado'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final nome = nomeController.text;
                final saldo = double.tryParse(saldoController.text) ?? 0;
                if (cliente == null) {
                  DBHelper.insertCliente(Cliente(nome: nome, saldoFiado: saldo));
                } else {
                  DBHelper.insertCliente(Cliente(id: cliente.id, nome: nome, saldoFiado: saldo));
                }
                Navigator.pop(context);
              },
              child: Text(cliente == null ? 'Adicionar' : 'Salvar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}

// TELA DE VENDAS
class VendasView extends StatelessWidget {
  const VendasView({super.key});

  @override
  Widget build(BuildContext context) {
    final valorController = TextEditingController();
    Cliente? selectedCliente;
    bool fiado = false;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venda')),
      body: Column(
        children: [
          FutureBuilder<List<Cliente>>(
            future: DBHelper.getClientes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              final clientes = snapshot.data ?? [];
              return DropdownButton<Cliente>(
                value: selectedCliente,
                onChanged: (Cliente? newCliente) {
                  selectedCliente = newCliente;
                },
                items: clientes.map((cliente) {
                  return DropdownMenuItem<Cliente>(
                    value: cliente,
                    child: Text(cliente.nome),
                  );
                }).toList(),
                hint: const Text('Selecione o cliente'),
              );
            },
          ),
          TextField(
            controller: valorController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor da venda'),
          ),
          Row(
            children: [
              Checkbox(
                value: fiado,
                onChanged: (bool? value) {
                  fiado = value ?? false;
                },
              ),
              const Text('Venda fiada'),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(valorController.text) ?? 0;
              if (selectedCliente != null && valor > 0) {
                final venda = Venda(
                  clienteId: selectedCliente!.id!,
                  valor: valor,
                  fiado: fiado,
                );
                DBHelper.insertVenda(venda);
                Navigator.pop(context);
              }
            },
            child: const Text('Registrar Venda'),
          ),
        ],
      ),
    );
  }
}

// TELA DE GASTOS
class GastosView extends StatelessWidget {
  const GastosView({super.key});

  @override
  Widget build(BuildContext context) {
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição do Gasto'),
            ),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor do Gasto'),
            ),
            ElevatedButton(
              onPressed: () {
                final descricao = descricaoController.text;
                final valor = double.tryParse(valorController.text) ?? 0;
                if (descricao.isNotEmpty && valor > 0) {
                  DBHelper.insertGasto(Gasto(descricao: descricao, valor: valor));
                  Navigator.pop(context);
                }
              },
              child: const Text('Registrar Gasto'),
            ),
          ],
        ),
      ),
    );
  }
}

// RELATÓRIO
class RelatorioView extends StatelessWidget {
  const RelatorioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório Financeiro')),
      body: FutureBuilder(
        future: Future.wait([
          DBHelper.getTotalVendas(),
          DBHelper.getTotalGastos(),
          DBHelper.getTotalFiado(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final totalVendas = snapshot.data?[0] ?? 0.0;
          final totalGastos = snapshot.data?[1] ?? 0.0;
          final totalFiado = snapshot.data?[2] ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total de Vendas: R\$ ${totalVendas.toStringAsFixed(2)}'),
                Text('Total de Gastos: R\$ ${totalGastos.toStringAsFixed(2)}'),
                Text('Total de Fiado: R\$ ${totalFiado.toStringAsFixed(2)}'),
              ],
            ),
          );
        },
      ),
    );
  }
}