class NumberToWords {
  static const List<String> _ones = [
    "",
    "ONE",
    "TWO",
    "THREE",
    "FOUR",
    "FIVE",
    "SIX",
    "SEVEN",
    "EIGHT",
    "NINE",
    "TEN",
    "ELEVEN",
    "TWELVE",
    "THIRTEEN",
    "FOURTEEN",
    "FIFTEEN",
    "SIXTEEN",
    "SEVENTEEN",
    "EIGHTEEN",
    "NINETEEN"
  ];

  static const List<String> _tens = [
    "",
    "",
    "TWENTY",
    "THIRTY",
    "FORTY",
    "FIFTY",
    "SIXTY",
    "SEVENTY",
    "EIGHTY",
    "NINETY"
  ];

  static String convert(int number) {
    if (number == 0) return "ZERO";
    return "${_convertRecursive(number)} ONLY".trim();
  }

  static String _convertRecursive(int n) {
    if (n < 20) {
      return _ones[n];
    }
    if (n < 100) {
      return "${_tens[n ~/ 10]} ${n % 10 != 0 ? _ones[n % 10] : ""}".trim();
    }
    if (n < 1000) {
      return "${_ones[n ~/ 100]} HUNDRED ${n % 100 != 0 ? _convertRecursive(n % 100) : ""}".trim();
    }
    if (n < 100000) {
      return "${_convertRecursive(n ~/ 1000)} THOUSAND ${n % 1000 != 0 ? _convertRecursive(n % 1000) : ""}".trim();
    }
    if (n < 10000000) {
      return "${_convertRecursive(n ~/ 100000)} LAKH ${n % 100000 != 0 ? _convertRecursive(n % 100000) : ""}".trim();
    }
    return "${_convertRecursive(n ~/ 10000000)} CRORE ${n % 10000000 != 0 ? _convertRecursive(n % 10000000) : ""}".trim();
  }
}
