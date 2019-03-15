import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/services/parser/transporter_parser.dart';
import 'package:test_api/test_api.dart';

void main() {
  const autoHTML = """
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Untitled Document</title>
<style type="text/css">
</style>
</head>
<body onload="MM_preloadImages('auto3-1.png','autoM45-1.png','auto5-1.png','auto13-1.png','auto21-1.png','auto28-1.png','autoM29-1.png','auto32-1.png','auto33-1.png','auto33b-1.png','auto40-1.png','auto46-1.png','autoE1-1.png','autoE2-1.png','autoE3-1.png','autoE4-1.png','autoE4b-1.png','autoE6-1.png','autoE7-1.png','autoM35-1.png','autoM44-1.png','autoE8-1.png','autoM22-1.png','autoM30-1.png','autos1-1.png','autos2-1.png','autos3-1.png','autos4-1.png')">
<div id="apDiv6">
  <p>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1207';" target="dreapta1" title="Linia 3" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image25','','auto3-1.png',1)"><img src="auto3.png" alt="auto3" name="Image25" width="41" height="41" border="0" id="Image25" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1553';" target="dreapta1" title="Linia 5" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image12','','auto5-1.png',1)"><img src="auto5.png" alt="auto5" name="Image12" width="41" height="41" border="0" id="Image12" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1066';" target="dreapta1" title="Linia 13" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image49','','auto13-1.png',1)"><img src="auto13.png" alt="auto13" name="Image49" width="41" height="41" border="0" id="Image49" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1146';" target="dreapta1" title="Linia 21" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image27','','auto21-1.png',1)"><img src="auto21.png" alt="auto21" name="Image27" width="41" height="41" border="0" id="Image27" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1226';" target="dreapta1" title="Linia 28" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image29','','auto28-1.png',1)"><img src="auto28.png" alt="auto28" name="Image29" width="41" height="41" border="0" id="Image29" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1546';" target="dreapta1" title="Linia 32" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image31','','auto32-1.png',1)"><img src="auto32.png" alt="auto32" name="Image31" width="41" height="41" border="0" id="Image31" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1046';" target="dreapta1" title="Linia 33" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image32','','auto33-1.png',1)"><img src="auto33.png" alt="auto33" name="Image32" width="41" height="41" border="0" id="Image32" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2466';" target="dreapta1" title="Linia 33 barat" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image33','','auto33b-1.png',1)"><img src="auto33b.png" alt="auto33b" name="Image33" width="41" height="41" border="0" id="Image33" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=886';" target="dreapta1" title="Linia 40" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image34','','auto40-1.png',1)"><img src="auto40.png" alt="auto40" name="Image34" width="41" height="41" border="0" id="Image34" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1406';" target="dreapta1" title="Linia 46" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image35','','auto46-1.png',1)"><img src="auto46.png" alt="auto46" name="Image35" width="41" height="41" border="0" id="Image35" /></a>
  </p>
  <p>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1550';" target="dreapta1" title="Linia Expres 1" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image36','','autoE1-1.png',1)"><img src="autoE1.png" alt="autoE1" name="Image36" width="41" height="41" border="0" id="Image36" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1551';" target="dreapta1" title="Linia Expres 2" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image37','','autoE2-1.png',1)"><img src="autoE2.png" alt="autoE2" name="Image37" width="41" height="41" border="0" id="Image37" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1552';" target="dreapta1" title="Linia Expres 3" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image38','','autoE3-1.png',1)"><img src="autoE3.png" alt="autoE3" name="Image38" width="41" height="41" border="0" id="Image38" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1926';" target="dreapta1" title="Linia Expres 4" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image39','','autoE4-1.png',1)"><img src="autoE4.png" alt="autoE4" name="Image39" width="41" height="41" border="0" id="Image39" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2486';" target="dreapta1" title="Linia Expres 4 barat" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image40','','autoE4b-1.png',1)"><img src="autoE4b.png" alt="autoE4b" name="Image40" width="41" height="41" border="0" id="Image40" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1928';" target="dreapta1" title="Linia Expres 6" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image41','','autoE6-1.png',1)"><img src="autoE6.png" alt="autoE6" name="Image41" width="41" height="41" border="0" id="Image41" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2026';" target="dreapta1" title="Linia Expres 7" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image42','','autoE7-1.png',1)"><img src="autoE7.png" alt="autoE7" name="Image42" width="41" height="41" border="0" id="Image42" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1547';" target="dreapta1" onmouseover="MM_swapImage('Image24','','autoE8-1.png',1)" onmouseout="MM_swapImgRestore()"><img src="autoE8.png" alt="autoE8" name="Image24" width="41" height="41" border="0" id="Image24" /></a>
  </p>
  <p>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='ab_m22.php';" target="dreapta1" title="Linia Metropolitan 22" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image48','','autoM22-1.png',1)"><img src="autoM22.png" alt="autoM22" name="Image48" width="41" height="41" border="0" id="Image48" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=3086';" target="dreapta1" title="Linia Metropolitan 29" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image30','','autoM29-1.png',1)"><img src="autoM29.png" alt="auto29" name="Image30" width="41" height="41" border="0" id="Image30" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1746';" target="dreapta1" title="Linia Metropolitan 30" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image50','','autoM30-1.png',1)"><img src="autoM30.png" alt="auto30" name="Image50" width="41" height="41" border="0" id="Image50" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1986';" target="dreapta1" title="Linia Metropolitan 35" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image45','','autoM35-1.png',1)"><img src="autoM35.png" alt="autoM35" name="Image45" width="41" height="41" border="0" id="Image45" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2506';" target="dreapta1" title="Linia Metropolitan 44" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image47','','autoM44-1.png',1)"><img src="autoM44.png" alt="autoM44" name="Image47" width="41" height="41" border="0" id="Image47" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2606';" target="dreapta1" title="Linia Metropolitan 45" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image51','','autoM45-1.png',1)"><img src="autoM45.png" alt="autoM45" name="Image51" width="41" height="41" border="0" id="Image51" /></a>
  </p>
  <p>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=3126';" target="dreapta1" title="Linia Speciala 1" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image52','','autos1-1.png',1)"><img src="autos1.png" alt="autos1" name="Image52" width="41" height="41" border="0" id="Image52" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=3146';" target="dreapta1" title="Linia Speciala 2" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image53','','autos2-1.png',1)"><img src="autos2.png" alt="autos2" name="Image53" width="41" height="41" border="0" id="Image53" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=3147';" target="dreapta1" title="Linia Speciala 3" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image54','','autos3-1.png',1)"><img src="autos3.png" alt="autos3" name="Image54" width="41" height="41" border="0" id="Image54" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=3166';" target="dreapta1" title="Linia Speciala 4" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image55','','autos4-1.png',1)"><img src="autos4.png" alt="autos4" name="Image55" width="41" height="41" border="0" id="Image55" /></a>
  </p>
</div>
</body>
</html>
  """;

  const tramHTML ="""
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Untitled Document</title>
<style type="text/css"></style>
</head>

<body onload="MM_preloadImages('tram1-1.png','tram2-1.png','tram4-1.png','tram7a-1.png','tram8-1.png','tram9-1.png','Tram6A-1.png','Tram6B-1.png')">
<div id="apDiv5">
  <p>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1106';" target="dreapta1" title="Linia 1" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image9','','tram1-1.png',1)"><img src="tram1.png" alt="tram1" name="Image9" width="41" height="41" border="0" id="Image9" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1126';" target="dreapta1" title="Linia 2" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image10','','tram2-1.png',1)"><img src="tram2.png" alt="tram2" name="Image10" width="41" height="41" border="0" id="Image10" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1266';" target="dreapta1" title="Linia 4" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image11','','tram4-1.png',1)"><img src="tram4.png" alt="tram4" name="Image11" width="41" height="41" border="0" id="Image11" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2686';" target="dreapta1" title="Linia 6a" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image12','','tram6A-1.png',1)"><img src="tram6A.png" alt="tram6a" name="Image12" width="41" height="41" border="0" id="Image12" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2706';" target="dreapta1" title="Linia 6b" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image13','','tram6B-1.png',1)"><img src="tram6B.png" alt="tram6b" name="Image13" width="41" height="41" border="0" id="Image13" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2846';" target="dreapta1" title="Linia 7" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image14','','tram7-1.png',1)"><img src="tram7.png" alt="tram7" name="Image14" width="41" height="41" border="0" id="Image14" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1558';" target="dreapta1" title="Linia 8" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image16','','tram8-1.png',1)"><img src="tram8.png" alt="tram8" name="Image16" width="41" height="41" border="0" id="Image16" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2406';" target="dreapta1" title="Linia 9" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image17','','tram9-1.png',1)"><img src="tram9.png" alt="tram9" name="Image17" width="41" height="41" border="0" id="Image17" /></a>
  </p>
</div>
</body>
</html>
  """;

   const trolHTML ="""
   <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Untitled Document</title>
<style type="text/css"></style>
</head>
<body onload="MM_preloadImages('trol11-1.png','trol14-1.png','trol15-1.png','trol16-1.png','trol17-1.png','trol18-1.png','trolM14-1.png','trolM11-1.png')">
<div id="apDiv5">
  <p>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=990';" target="dreapta1" title="Linia 11" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image8','','trol11-1.png',1)"><img src="trol11.png" alt="trol11" name="Image8" width="41" height="41" border="0" id="Image8" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2786';" target="dreapta1" title="Linia M11" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image15','','trolM11-1.png',1)"><img src="trolM11.png" name="Image15" width="41" height="41" border="0" id="Image15" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1006';" target="dreapta1" title="Linia 14" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image9','','trol14-1.png',1)"><img src="trol14.png" alt="trol14" name="Image9" width="41" height="41" border="0" id="Image9" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=2766';" target="dreapta1" title="Linia M14" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image14','','trolM14-1.png',1)"><img src="trolM14.png" alt="trolM14" name="Image14" width="41" height="41" border="0" id="Image14" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=989';" target="dreapta1" title="Linia 15" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image10','','trol15-1.png',1)"><img src="trol15.png" alt="trol15" name="Image10" width="41" height="41" border="0" id="Image10" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1206';" target="dreapta1" title="Linia 16" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image11','','trol16-1.png',1)"><img src="trol16.png" alt="trol16" name="Image11" width="41" height="41" border="0" id="Image11" /></a>
  <br>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1086';" target="dreapta1" title="Linia 17" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image12','','trol17-1.png',1)"><img src="trol17.png" alt="trol17" name="Image12" width="41" height="41" border="0" id="Image12" /></a>
  <a href="javascript:void(0)" onclick="parent.dreapta1.location.href='trasee.php?param1=1166';" target="dreapta1" title="Linia 18" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('Image13','','trol18-1.png',1)"><img src="trol18.png" alt="trol18" name="Image13" width="41" height="41" border="0" id="Image13" /></a>
  </p>
</div>
</body>
</html>
   """;

  TransporterParser parser;

  setUp((){
    parser = TransporterParserImpl();
  });

  test("should parse auto", () {
    var parse = parser.parse(TransporterType.bus, autoHTML);
    print(parse.join("\n"));
  });

  test("should parse tram", () {
    var parse = parser.parse(TransporterType.tram, tramHTML);
    print(parse.join("\n"));
  });

  test("should parse trol", () {
    var parse = parser.parse(TransporterType.trolley, trolHTML);
    print(parse.join("\n"));
  });
}
