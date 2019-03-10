import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:test_api/test_api.dart';

void main() {
  const htmlResult = """  
<!DOCTYPE html>
<html>
<head>
<title>R.A.T. Timisoara</title>
<style>
    body {
    background-image: url(bkg3.jpg);
	background-attachment:fixed;
	background-position:center;
    }
	body {
    font-family: sans-serif;
	font-weight: 300;
}
</style>    
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"></head>

<body>
 
<ul>
<table bgcolor=0048A1 style='color:white;' border='0'><tr>
<td align=center><b>Linia 40 spre Stuparilor</b></td></tr>
</table><br><br><table bgcolor=D8D8D8 border='0'><tr>
    <td align=center width="200"><b>Stația</b></td>
    <td align=center width="60"><b>Sosire</b></td>
</tr>
</table><table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>T. Grozăvescu</b></td>
    <td align=center width="60"><b>1 min.</b></td>
</tr>
</table><table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Popa Șapcă</b></td>
    <td align=center width="60"><b>12:17</b></td>
</tr>
</table><table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Galeria 1</b></td>
    <td align=center width="60"><b>1 min.</b></td>
</tr>
</table><table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Div 9 Cavalerie</b></td>
    <td align=center width="60"><b>3 min.</b></td>
</tr>
</table><table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Complex Terra</b></td>
    <td align=center width="60"><b>4 min.</b></td>
</tr>
</table><table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Gara de Est</b></td>
    <td align=center width="60"><b>6 min.</b></td>
</tr>
</table><table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Stuparilor</b></td>
    <td align=center width="60"><b>12:15</b></td>
</tr>
</table><br><br><table bgcolor=0048A1 style='color:white;' border='0'><tr>
<td align=center><b>Linia 40 spre T. Grozăvescu</b></td></tr>
</table><br><br><table bgcolor=D8D8D8 border='0'><tr>
    <td align=center width="200"><b>Stația</b></td>
    <td align=center width="60"><b>Sosire
</b></td>
<table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Stuparilor</b></td>
    <td align=center width="60"><b>12:15</b></td>
</tr>
</table>
<table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Holdelor</b></td>
    <td align=center width="60"><b>12:22</b></td>
</tr>
</table>
<table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Ap. Petru și Pavel</b></td>
    <td align=center width="60"><b>1 min.</b></td>
</tr>
</table>
<table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Pomiculturii</b></td>
    <td align=center width="60"><b>3 min.</b></td>
</tr>
</table>
<table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Div 9 Cavalerie</b></td>
    <td align=center width="60"><b>4 min.</b></td>
</tr>
</table>
<table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Iulius Mall</b></td>
    <td align=center width="60"><b>6 min.</b></td>
</tr>
</table>
<table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>Popa Șapcă</b></td>
    <td align=center width="60"><b>8 min.</b></td>
</tr>
</table>
<table bgcolor=D8D8D8 border='0'><tr>
    <td align=left width="200"><b>T. Grozăvescu</b></td>
    <td align=center width="60"><b>1 min.</b></td>
</tr>
</table>
    
</ul>
</body>
</html>
  """;

  test("should parse the document", () {
    final route = RouteArrivalParserImpl(
        ArrivalTimeConverterImpl()).parse(htmlResult);
        print(route);
  });
}