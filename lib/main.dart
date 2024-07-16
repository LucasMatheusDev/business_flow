import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:bussiness_flow_cli/bussiness_flow_cli.dart';
import 'package:bussiness_flow_cli/interpreted_text.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Flow Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<Uint8List> _images = [];
  bool _isLoading = false;

  Future<void> _generateImages(String input) async {
    setState(() {
      _isLoading = true;
    });

    const instructAi = """
      voce deve entender a regra de negocio do texto, separe ele em etapas logicas e salve.
      Pegue as etapas logicas que voce salvou e crie um diagrama seguindo a sintaxe do PlantUML.

      siga esse exemplo:
      @startuml
      start
      :Usu rio efetua login;
      if (Usu rio seleciona "Esqueceu a senha?") then (sim)
        :Usu rio vai para tela de recupera  o de senha;
        if (Recupera  o de senha bem sucedida?) then (sim)
          :Usu rio volta para o fluxo de login;
        else (n o)
          stop
        endif
      else (n o)
        :Usu rio insere email e senha;
        if (Login bem sucedido?) then (sim)
          :Usu rio vai para tela inicial;
        else (n o)
          repeat
            :Usu rio erra a senha;
            if (Erro de senha pela terceira vez?) then (sim)
              :Usu rio   notificado do bloqueio da conta;
              break
            endif
          repeat while (Erro de senha pela terceira vez?) is (n o)
        endif
      endif
      stop
      @enduml
    """;

    List<Future<Uint8List>> imageFutures = List.generate(3, (_) async {
      final platUmlText =
          await InterpretedText(input, instructAi).generateText();
      final plantUmlGenerate = PlantUmlGenerate(platUmlText);
      return await plantUmlGenerate.generateImage() as Uint8List;
    });

    List<Uint8List> images = await Future.wait(imageFutures);

    setState(() {
      _images = images;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Web CLI'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  height: 200,
                  child: TextField(
                    controller: _controller,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Inserir Regra de negócio',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _generateImages(_controller.text),
                child: const Text('Gerar Diagramas'),
              ),
              const SizedBox(height: 16.0),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              if (_images.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.memory(_images[index]),
                            const SizedBox(height: 16.0),
                            IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () async {
                                final bytes = _images[index];
                                final blob = html.Blob([bytes]);
                                final url =
                                    html.Url.createObjectUrlFromBlob(blob);
                                final anchor = html.AnchorElement(href: url)
                                  ..setAttribute('download', 'image$index.png')
                                  ..click();
                                html.Url.revokeObjectUrl(url);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
