import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

const apiBase = 'http://10.0.2.2:8000';

void main() => runApp(const SpeakMateApp());

class SpeakMateApp extends StatelessWidget {
  const SpeakMateApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeakMate DZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3157d5)),
        scaffoldBackgroundColor: const Color(0xfff5f7fb),
        useMaterial3: true,
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int tab=0;
  final pages=const [HomePage(), PracticePage(), ProgressPage(), ResearchPage()];
  @override Widget build(BuildContext c)=>Scaffold(
    body: pages[tab],
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected:(i)=>setState(()=>tab=i),
      destinations: const [
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
        NavigationDestination(icon:Icon(Icons.mic_none),selectedIcon:Icon(Icons.mic),label:'Practice'),
        NavigationDestination(icon:Icon(Icons.insights_outlined),selectedIcon:Icon(Icons.insights),label:'Progress'),
        NavigationDestination(icon:Icon(Icons.science_outlined),selectedIcon:Icon(Icons.science),label:'Research'),
      ],
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override Widget build(BuildContext c)=>SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
    const Text('🎙 SpeakMate DZ',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
    const Text('Your AI English speaking partner',style:TextStyle(color:Colors.grey)),
    const SizedBox(height:20),
    Card(color:const Color(0xffeaf0ff),child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Practice spoken English with guided AI conversations.',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),
      const SizedBox(height:8),const Text('Speak naturally, receive formative feedback, and track your development.'),
      const SizedBox(height:16),
      FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ConversationPage(mode:'University English',level:'B1'))),icon:const Icon(Icons.mic),label:const Text('Start speaking'))
    ]))),
    const SizedBox(height:16),
    Row(children:[
      _stat('0','Sessions'),_stat('0m','Speaking'),_stat('0%','Progress')
    ]),
    const SizedBox(height:16),
    const Card(child:ListTile(leading:Icon(Icons.school),title:Text('Today\\'s recommendation'),subtitle:Text('University discussion · B1\\nExpress an opinion and support it with an example.')))
  ]));
}
Widget _stat(String n,String l)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[Text(n,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text(l,style:const TextStyle(color:Colors.grey))]))));

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});
  @override State<PracticePage> createState()=>_PracticePageState();
}
class _PracticePageState extends State<PracticePage>{
  String mode='Everyday English',level='B1';
  final modes=['Everyday English','University English','Professional English','Debate','Role Play','Free Conversation'];
  final icons=[Icons.chat_bubble_outline,Icons.school,Icons.work_outline,Icons.gavel,Icons.theater_comedy,Icons.forum];
  @override Widget build(BuildContext c)=>SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
    const Text('Choose practice',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
    const Text('Select a scenario and start talking.',style:TextStyle(color:Colors.grey)),
    const SizedBox(height:16),
    ...List.generate(modes.length,(i)=>Card(
      color:mode==modes[i]?const Color(0xffeef2ff):null,
      child:ListTile(leading:Icon(icons[i]),title:Text(modes[i]),subtitle:Text(_desc(modes[i])),
        trailing:Radio<String>(value:modes[i],groupValue:mode,onChanged:(v)=>setState(()=>mode=v!)),
        onTap:()=>setState(()=>mode=modes[i])))),
    const SizedBox(height:10),
    DropdownButtonFormField<String>(value:level,decoration:const InputDecoration(labelText:'Level',border:OutlineInputBorder()),items:['A2','B1','B2','C1'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>level=v!)),
    const SizedBox(height:14),
    FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ConversationPage(mode:mode,level:level))),icon:const Icon(Icons.mic),label:const Text('Begin conversation'))
  ]));
}
String _desc(String m)=>switch(m){ 'Everyday English'=>'Daily situations and informal conversation.','University English'=>'Academic discussion and opinions.','Professional English'=>'Interviews and workplace situations.','Debate'=>'Defend an argument and respond to challenges.','Role Play'=>'Real-world communication scenarios.',_=>'Open conversation on any topic.'};

class ConversationPage extends StatefulWidget{
  final String mode,level; const ConversationPage({super.key,required this.mode,required this.level});
  @override State<ConversationPage> createState()=>_ConversationPageState();
}
class _ConversationPageState extends State<ConversationPage>{
  final input=TextEditingController(); final speech=stt.SpeechToText();
  bool listening=false,loading=false; List<Map<String,String>> messages=[]; DateTime started=DateTime.now();
  @override void initState(){super.initState();_start();}
  Future<void> _start() async{
    setState(()=>loading=true);
    try{
      final r=await http.post(Uri.parse('$apiBase/api/session/start'),headers:{'Content-Type':'application/json'},body:jsonEncode({'mode':widget.mode,'level':widget.level}));
      final j=jsonDecode(r.body); _add('assistant',j['prompt']??'Tell me about yourself.');
    }catch(_){_add('assistant',_offlinePrompt());}
    setState(()=>loading=false);
  }
  String _offlinePrompt()=>widget.mode=='Debate'?'Some people believe AI should be allowed in university assignments. What is your position?':'Tell me something interesting about your day and explain why it was important.';
  void _add(String role,String text){setState(()=>messages.add({'role':role,'text':text}));}
  Future<void> _send() async{
    final t=input.text.trim(); if(t.isEmpty)return; input.clear(); _add('user',t); setState(()=>loading=true);
    try{
      final r=await http.post(Uri.parse('$apiBase/api/session/message'),headers:{'Content-Type':'application/json'},body:jsonEncode({'session':{'mode':widget.mode,'level':widget.level},'messages':messages,'text':t}));
      final j=jsonDecode(r.body); _add('assistant',j['reply']??'Tell me more.');
    }catch(_){_add('assistant','Good. Could you explain that in a little more detail and give me an example?');}
    setState(()=>loading=false);
  }
  Future<void> _listen() async{
    if(listening){await speech.stop();setState(()=>listening=false);return;}
    final ok=await speech.initialize(onStatus:(s){if(s=='done')setState(()=>listening=false);});
    if(!ok)return;
    setState(()=>listening=true);
    await speech.listen(localeId:'en_US',onResult:(r){setState(()=>input.text=r.recognizedWords);if(r.finalResult){_send();}});
  }
  Future<void> _finish() async{
    setState(()=>loading=true);
    try{
      final r=await http.post(Uri.parse('$apiBase/api/session/finish'),headers:{'Content-Type':'application/json'},body:jsonEncode({'session':{'mode':widget.mode,'level':widget.level},'messages':messages,'duration_seconds':DateTime.now().difference(started).inSeconds}));
      final j=jsonDecode(r.body); if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ReportPage(data:j)));
    }catch(_){if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const ReportPage(data:null)));}
  }
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.mode),actions:[TextButton(onPressed:_finish,child:const Text('Finish'))]),body:SafeArea(child:Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:Row(children:[Chip(label:Text(widget.level)),const SizedBox(width:8),if(loading)const Text('Thinking…',style:TextStyle(color:Colors.grey))])),
    Expanded(child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:messages.length,itemBuilder:(_,i){final m=messages[i];return Align(alignment:m['role']=='user'?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(13),constraints:const BoxConstraints(maxWidth:330),decoration:BoxDecoration(color:m['role']=='user'?const Color(0xff3157d5):Colors.white,borderRadius:BorderRadius.circular(15)),child:Text(m['text']!,style:TextStyle(color:m['role']=='user'?Colors.white:Colors.black87)));})),
    Padding(padding:const EdgeInsets.all(10),child:Row(children:[IconButton.filled(onPressed:_listen,icon:Icon(listening?Icons.stop:Icons.mic)),const SizedBox(width:8),Expanded(child:TextField(controller:input,decoration:const InputDecoration(hintText:'Type or speak your answer',border:OutlineInputBorder()),onSubmitted:(_)=>_send())),const SizedBox(width:8),IconButton.filled(onPressed:_send,icon:const Icon(Icons.send))]))
  ])));
}

class ReportPage extends StatelessWidget{
  final Map<String,dynamic>? data; const ReportPage({super.key,this.data});
  @override Widget build(BuildContext c){final s=(data?['scores'] as Map?)?.cast<String,dynamic>()??{'fluency':0,'grammar':0,'vocabulary':0,'pronunciation':0};final f=(data?['feedback'] as List?)?.map((x)=>x.toString()).toList()??['Complete more sessions to generate personalised feedback.'];return Scaffold(appBar:AppBar(title:const Text('Speaking report')),body:ListView(padding:const EdgeInsets.all(18),children:[const Text('Your performance',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),const SizedBox(height:16),...s.entries.map((e)=>Card(child:ListTile(title:Text(e.key[0].toUpperCase()+e.key.substring(1)),trailing:Text('${e.value}%',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))))),const SizedBox(height:10),const Text('Formative feedback',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),...f.map((x)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Text(x)))),FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('Back to practice'))]));}
}

class ProgressPage extends StatelessWidget{
  const ProgressPage({super.key});
  @override Widget build(BuildContext c)=>SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[const Text('My Progress',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),const Text('Track your speaking development over time.',style:TextStyle(color:Colors.grey)),const SizedBox(height:18),_skill('🗣 Fluency',78),_skill('✏ Grammar',71),_skill('📚 Vocabulary',76),_skill('🔊 Pronunciation',82),const Card(child:ListTile(leading:Icon(Icons.flag),title:Text('Recommended focus'),subtitle:Text('Repeat a university discussion and practise supporting opinions with examples.')))]));
}
Widget _skill(String name,int v)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(name),Text('$v%')]),const SizedBox(height:8),LinearProgressIndicator(value:v/100,minHeight:8)])));

class ResearchPage extends StatelessWidget{
  const ResearchPage({super.key});
  @override Widget build(BuildContext c)=>SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[const Text('Research Dashboard',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),const Text('Prototype tools for the Master 2 study.',style:TextStyle(color:Colors.grey)),const SizedBox(height:18),const Card(child:ListTile(title:Text('Example cohort'),trailing:Text('30 participants'))),const Card(child:ListTile(title:Text('Intervention'),trailing:Text('6 weeks'))),const Card(child:ListTile(title:Text('Target frequency'),trailing:Text('3 sessions/week'))),const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('For the real study, use participant codes, informed consent, institutional approval, a validated speaking rubric, and a defined data-retention/deletion policy.')))]));
}
