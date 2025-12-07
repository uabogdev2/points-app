enum GameMode {
  solo,        // Mode Solo vs IA
  duo,         // Duo sur le même téléphone
  matchmaking, // Matchmaking en ligne
  private,     // Partie privée avec code
  invitation,  // Partie via invitation
}

enum GridSize {
  small(3),
  medium(5),
  large(8),
  xlarge(12);

  final int value;
  const GridSize(this.value);
  
  String get label {
    switch (this) {
      case GridSize.small:
        return '3×3';
      case GridSize.medium:
        return '5×5';
      case GridSize.large:
        return '8×8';
      case GridSize.xlarge:
        return '12×12';
    }
  }
}

