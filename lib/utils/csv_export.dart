String csvEscape(String s) {
  if (s.isNotEmpty && ['=', '+', '-', '@'].contains(s[0])) {
    s = '\t$s';
  }
  return '"${s.replaceAll('"', '""')}"';
}
