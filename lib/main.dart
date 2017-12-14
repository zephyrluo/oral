import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:medcorder_audio/medcorder_audio.dart';
import 'dart:typed_data';

void main() {
  runApp(new MyApp());
}

class Sentence {
  const Sentence(this.index, this.entxt, this.cntxt,
      this.audioPos0, this.audioPos1, this.audioid); // ignore: const_constructor_with_non_final_field
  final int index;
  final String entxt;
  final String cntxt;
  final double audioPos0;
  final double audioPos1;
  final int audioid;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: '流利说英语',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title:  '流利说英语'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class SentenceListItem extends StatelessWidget {
  SentenceListItem({Sentence sentence})
      : entxt = sentence.entxt,
        index = sentence.index,
        cntxt = sentence.cntxt,
        super(key: new ObjectKey(sentence));

  final int index;
  final String entxt;
  final String cntxt;

  Color _getColor(BuildContext context) {
    return Colors.black54;
  }

  TextStyle _getTextStyle(BuildContext context, String txt) {
    return new TextStyle(
      color: Colors.black54,
      fontSize: 18.0
    );
  }
  MediaQueryData queryData;
  @override
  Widget build(BuildContext context) {
    if (entxt.length == 0) {
      return new Container();
    }
    queryData = MediaQuery.of(context);
    double devicePixelRatio = queryData.devicePixelRatio;
//    ScrollableState scrollableState = Scrollable.of(context);
//    ScrollPosition position = scrollableState.position;
//    ps.sc.attach(position);
    return new Container(
        margin: const EdgeInsets.all(3.0),
        padding: const EdgeInsets.all(5.0),
        child: new Material(
            type: MaterialType.card,
            elevation: 2.0,
            child: new Row(
              children: [
                new Container(
                    height: Theme.of(context).textTheme.display1.fontSize * 1.1 + 110,
                    padding: const EdgeInsets.only(left:15.0,top:15.0),
                    alignment: Alignment.topCenter,
                    child: new Icon(
                      Icons.wb_incandescent,
                      color: ps.hightLight==index && ps.playState == PLAY_STAT.playing? Colors.yellow : Colors.grey,
                    )
                ),
                new Expanded(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      new Container(
                          padding: const EdgeInsets.only(top:20.0, bottom: 10.0, left: 15.0),
                          child: new Text( entxt, style: _getTextStyle(context, entxt), maxLines: 3,),
                          height:Theme.of(context).textTheme.display1.fontSize
                      ),
                      new Container(
                          padding: const EdgeInsets.only(top:10.0, left: 15.0),
                          child: new Text( cntxt, style: _getTextStyle(context, entxt), maxLines: 3,),
                          height:Theme.of(context).textTheme.display1.fontSize
                      ),
                      new ButtonTheme.bar(
                        child: new ButtonBar(
                          children: <Widget>[
                            new FlatButton(
                              child: const Text('重听'),
                              onPressed: () {
                                ps.playAgain(index);
                              },
                            ),
                            new FlatButton(
                              child: const Text('跳过'),
                              onPressed: () {
                                ps.skipPlay(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                ),
              ],
            )
        )
    );
  }
}
enum PLAY_STAT{
  init,
  playing,
  paused,
  stoped,
  error,
}

class PlayState {

  PlayState(PLAY_STAT state, int high) {
    this.playState = state;
    this.hightLight = high;
  }
  PLAY_STAT playState;
  int hightLight;

  ScrollController sc;
  MediaQueryData mqd;

  double lastpos;

  void playAgain(int index) {}

  void skipPlay(int index) {}
}


PlayState ps = new PlayState(PLAY_STAT.init, 0);

class Choice {
  const Choice({ this.title, this.icon });
  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'To Speaker',   icon: Icons.volume_up),
  const Choice(title: 'Delay Show',   icon: Icons.map),
  const Choice(title: 'Show All',     icon: Icons.g_translate),
  const Choice(title: 'Only English', icon: Icons.title),
  const Choice(title: 'Only Chinese', icon: Icons.translate),
  const Choice(title: 'Hide App',     icon: Icons.home),
];

class _MyHomePageState extends State<MyHomePage> {

  final List<Sentence> sentenses = new List<Sentence>();

  MedcorderAudio audioModule = new MedcorderAudio();
  String curMP3FilePath;

  Future<String> _readLRC() async {
    try {
      return rootBundle.loadString('assets/res/1-20.lrc');
    } on FileSystemException {
      return "";
    }
  }

  void _enterRec() {

  }

  double parseTime(String str) {
    List<String> v = str.split(":");
    double ret = 0.0;
    v.forEach((String tmv) {
      ret = ret*60+double.parse(tmv);
    });
    return ret;
  }


  void _onEvent(dynamic event){
    if(event['code'] == 'recording'){
      double power = event['peakPowerForChannel'];
      setState((){
      });
    }
    if(event['code'] == 'playing') {
      double currentTime = event['currentTime'];
      switchHightLight(currentTime);
    }
    if(event['code'] == 'audioPlayerDidFinishPlaying') {
      setState((){
        ps.playState = PLAY_STAT.stoped;
        ps.lastpos = 0.0;
      });
    }
  }
  void switchHightLight(double tm) {
    ps.lastpos = tm;
    sentenses.forEach((Sentence s) {
      if (s.audioPos0 <= tm && s.audioPos1 > tm) {
        if(ps.hightLight != s.index) {
          setState(() {
            int selind = s.index;
            ps.hightLight = selind;
            if(selind%3 == 0) {
              if(selind>=sentenses.length-4) {
                selind=sentenses.length-4;
              }
//              final RenderObject object = context.findRenderObject();
//              ps.sc.positions.elementAt(selind).ensureVisible(object);
              ps.sc.animateTo(selind*ps.mqd.size.height/4.5,
                  curve:Curves.decelerate,
                  duration:new Duration(milliseconds:500));
            }
          });
        }
      }});
  }
  void _handleArrowButtonPress(BuildContext context, int delta) {
    final TabController controller = DefaultTabController.of(context);
    if (!controller.indexIsChanging)
      controller.animateTo((controller.index + delta).clamp(0, sentenses.length-1));
  }
  Future<String> moveMp3File() async {
    String appDocPath = (await getApplicationDocumentsDirectory()).path;
    await audioModule.setAudioSettings();

    File mp3file = new File("$appDocPath/1-20.mp3");
    if(await mp3file.exists()) return mp3file.path;
    try {
      ByteData data = await rootBundle.load('assets/res/1-20.mp3');
      await mp3file.writeAsBytes(data.buffer.asUint8List());
    } on FileSystemException {
      ps.playState = PLAY_STAT.error;
      ps.lastpos = 0.0;
      return "";
    }
    return mp3file.path;
  }

  void _startPlay(double pos) {
    setState((){
      ps.playState = PLAY_STAT.playing;
      ps.hightLight = 0;
      ps.sc.jumpTo(0.0);
    });
    switchHightLight(pos);
    audioModule.startPlay({"file": curMP3FilePath, "position": pos,});
  }

  void _stopPlay() {
    setState((){
      ps.playState = PLAY_STAT.stoped;
    });
    audioModule.stopPlay();
  }

  @override
  void initState() {
    super.initState();

    audioModule.setCallBack((dynamic data){
      _onEvent(data);
    });

    ps.sc =  new ScrollController();

    moveMp3File().then((String mp3path) {
      if ( mp3path.length <= 0) return;
      curMP3FilePath = mp3path;

      _startPlay(0.0);
    });

    _readLRC().then((String value) {
      setState(() {
        List<String> ens    = new List<String>();
        List<String> cns    = new List<String>();
        List<double> start  = new List<double>();
        List<double> end    = new List<double>();

        double startVal;

        value.split("\n").forEach((String title) {
          List<String> ts = title.split('|');

          if(ts.length<1) return;

          String tick=ts[0].trim();
          if (tick.length<=0) return;

          startVal = parseTime(tick.substring(1,tick.length-1));

          if(ts.length<3) return;

          ens.add(ts[1]);
          cns.add(ts[2]);

          if(end.length>0) {
            end[end.length-1] = startVal;
          }
          start.add(startVal);
          end.add(0.0);
        });
        if(end.length>0) {
          end[end.length-1] = startVal;
        }
        ens.asMap().forEach((i, v){
          this.sentenses.add(new Sentence(i, v, cns[i], start[i], end[i], 0));
        });
        this.sentenses.add(new Sentence(sentenses.length, "", "",
            end[sentenses.length-1], end[sentenses.length-1], 0));
      });

    });
  }


  void _select(Choice choice) {
    setState(() {
    });
  }
  @override
  Widget build(BuildContext context) {
    ps.mqd = MediaQuery.of(context);
    print("size:"+ps.mqd.size.toString());
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton( // action button
            icon: new Icon(choices[0].icon),
            onPressed: () { _select(choices[0]); },
          ),
          new IconButton(
            icon: new Icon(choices[1].icon),
            onPressed: () { _select(choices[1]); },
          ),
          new PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.skip(2).map((Choice choice) {
                return new PopupMenuItem<Choice>(
                    value: choice,
                    child: new ListTile(
                      leading:new Icon(choice.icon),
                      title:  new Text(choice.title),
                    )
                );
              }).toList();
            },
          ),
        ],
      ),
      body: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        controller :  ps.sc,
        itemExtent: ps.mqd.size.height/4,
        children: sentenses.map((Sentence sentence) {
          return new SentenceListItem(
            sentence: sentence,
          );
        }).toList(),
      ),

      bottomNavigationBar: new BottomNavigationBar(
        currentIndex: 1,
        onTap: (int index) {
         switch(index) {
           case 1:
             if(ps.playState==PLAY_STAT.playing) {
               _stopPlay();
             }
             else {
               _startPlay(ps.lastpos);
             }
             break;
         }
        },
        items: <BottomNavigationBarItem>[
          new BottomNavigationBarItem(icon: const Icon(Icons.library_books),  title: new Text('课程')),
          ps.playState!=PLAY_STAT.playing?
          new BottomNavigationBarItem(icon: const Icon(Icons.play_arrow),     title: new Text('播放')):
          new BottomNavigationBarItem(icon: const Icon(Icons.stop),           title: new Text('停止')),
          new BottomNavigationBarItem(icon: const Icon(Icons.person),         title: new Text('个人')),
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _enterRec,
        tooltip: 'Enter TEST',
        child: new Icon(Icons.keyboard_voice),
      ),
    );
  }
}


