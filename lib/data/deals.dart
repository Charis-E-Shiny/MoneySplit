/// SAMPLE deals shown on the Discover tab. Replace with a Firestore
/// collection or a partner API (MakeMyTrip, Dineout, etc.) for real deals.
class Deal {
  final String title, merchant, category, badge;
  final double price;
  const Deal(this.title, this.merchant, this.category, this.price, this.badge);
}

const sampleDeals = <Deal>[
  Deal('Goa Beach Resort - 3 Nights', 'MakeMyTrip', 'Travel', 8000, 'BEST VALUE'),
  Deal('Rooftop Dinner for 4', 'Dineout', 'Food', 3200, 'FOODIE FAVORITE'),
  Deal('Mumbai to Goa Flights x4', 'MakeMyTrip', 'Travel', 18400, 'GROUP FARE'),
  Deal('Seafood Platter Feast', 'Zomato', 'Food', 1800, 'TRENDING'),
  Deal('Beach Shack Stay - 2 Nights', 'MakeMyTrip', 'Travel', 5600, 'WEEKEND DEAL'),
  Deal('Brunch Buffet for 6', 'Dineout', 'Food', 4200, 'GROUP DEAL'),
];
