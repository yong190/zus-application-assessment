String formatMoney(int sen) =>
    'RM${sen ~/ 100}.${(sen % 100).toString().padLeft(2, '0')}';
