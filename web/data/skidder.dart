import 'dart:async' show Future;
import 'dart:convert' show jsonEncode, jsonDecode, utf8;
import 'dart:io' show File, HttpClient, HttpClientRequest, HttpClientResponse, exit;

const logsFile = "logs.txt";
const outputFile = "logs.json";
const imageFolder = "images/";
const paldemicFolder = "paldemics/";
const mp3Folder = "mp3s/";
const baseUrl = "http://farragnarok.com/PodCasts/";

const batch = 32;
void main() async{
  final startTime = DateTime.now().millisecondsSinceEpoch;

  final output = await File(outputFile).openWrite();
  final input = await File(logsFile).readAsLines();
  final jsons = <MapEntry>[];

  for(int i = 0; i < input.length; i += batch){
    final subinput = input.sublist(i, i + batch > input.length ? input.length : i + batch);
    jsons.addAll(await Future.wait(subinput.map((log) async{
      final client = HttpClient();
      final json = await client.getUrl(Uri.parse("$baseUrl$log.json"))
          .then((HttpClientRequest request) => request.close())
          .then(responseToString)
          .then(stringToJson);
      json["image"] = await checkAssociatedFile(client, log, 'png', imageFolder);
      json["paldemic"] = await checkAssociatedFile(client, log, 'paldemic', paldemicFolder);
//      json["audio"] = await checkAssociatedFile(client, log, 'mp3', mp3Folder);
      return MapEntry(log, json);
    })));
    print("done with logs up to ${i+batch}");
  }

  final map = Map.fromEntries(jsons);
  await output.write(jsonEncode(map));
  await output.close();

  final endTime = DateTime.now().millisecondsSinceEpoch;
  final totalTime = endTime - startTime;
  print("This took $totalTime milliseconds");
  exit(0);
}
Future<String> responseToString(HttpClientResponse r) {
  return r.transform(utf8.decoder).first;
}
Map<String, Object> stringToJson(String str){
  try {
    return jsonDecode(str);
  } catch (_) {
    return {"ERROR":"FAILED TO DECODE JSON"};
  }
}
Future<bool> checkAssociatedFile(HttpClient client, String log, String fileType, String folder){
  return client.getUrl(Uri.parse("$baseUrl$log.$fileType"))
      .then((HttpClientRequest q) => q.close())
      .then((HttpClientResponse r){
        if(r.statusCode == 200){
          r.pipe(File('$folder$log.$fileType').openWrite());
          return true;
        }else{
          return false;
        }
      });
}