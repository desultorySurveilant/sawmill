import 'dart:convert' show jsonDecode;
import 'dart:html';

void main() async{
  final json = await HttpRequest.getString('data/logs.json').then(jsonDecode);

  final output = querySelector('#output');
  final searchBar = InputElement();
  final searchButton = ButtonElement()..text = "search";
  output.append(searchBar);
  output.append(searchButton);
  final results = DivElement();
  output.append(results);

  searchButton.onClick.listen((_){
    results.text = json[searchBar.value].toString();
  });
  searchBar.onKeyPress.listen((e) {
    if (e.keyCode == 13) results.text = json[searchBar.value].toString();
  });
}
