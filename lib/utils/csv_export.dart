String csvEscape(String s) {
  s = s.replaceAll('"', '""');
  if (s.isNotEmpty && ['=', '+', '-', '@'].contains(s[0])) {
    s = s.replaceFirst(RegExp(r'^[=+\-@]+'), '');
  }
  return '"$s"';
}
