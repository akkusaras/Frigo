/// The three visual shelves inside the fridge.
enum ShelfCategory {
  dairy(shelfLabel: 'DAIRY', displayName: 'Dairy'),
  meatAndLeftovers(
    shelfLabel: 'MEAT AND LEFTOVERS',
    displayName: 'Meat and leftovers',
  ),
  vegetableDrawer(
    shelfLabel: 'VEGETABLE DRAWER',
    displayName: 'Vegetable drawer',
  );

  const ShelfCategory({required this.shelfLabel, required this.displayName});

  /// Upper-case label printed on the fridge shelf (`DAIRY`).
  final String shelfLabel;

  /// Sentence-case name used in lists (`Vegetable drawer`).
  final String displayName;
}
