import 'dart:convert';

import 'package:digital_currency_analyser/model/coin_model.dart';
import 'package:digital_currency_analyser/page/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helper/currency_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String urlListMarket =
      'https://api.coingecko.com/api/v3/coins/markets?vs_currency=idr&order=market_cap_desc&per_page=100&page=1&sparkline=false';
  List<CoinModel> listCoin = [];
  late Future<List<CoinModel>> listCoinFuture;
  bool isFirstTimeDataAccess = true;

  Future<List<CoinModel>> getListCoins() async {
    final response = await http.get(Uri.parse(urlListMarket));
    if (response.statusCode == 200) {
      List result = json.decode(response.body);
      final data = result.map((json) => CoinModel.fromJson(json)).toList();
      return data;
    } else {
      return <CoinModel>[];
    }
  }

  @override
  void initState() {
    super.initState();
    listCoinFuture = getListCoins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Currency'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: FutureBuilder(
            future: listCoinFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (isFirstTimeDataAccess) {
                  listCoin = snapshot.data!;
                  isFirstTimeDataAccess = false;
                }

                return Column(
                  children: [
                    TextField(
                      onChanged: (query) {
                        // Convert the query to lowercase to make it case-insensitive
                        query = query.toLowerCase();

                        // Filter coins where the coin name contains the query, case-insensitive
                        List<CoinModel> searchResult = snapshot.data!.where((coin) {
                          // Convert coin.name to lowercase for case-insensitive comparison
                          String name = coin.name!.toLowerCase();
                          return name.contains(query); // Check if the query is part of the coin name
                        }).toList();

                        // Update the list of coins based on the search result
                        setState(() {
                          listCoin = searchResult;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Search coins',
                      ),
                    ),
                    SizedBox(height: 24),
                    Expanded(
                      child: listCoin.isEmpty
                          ? Center(
                        child: Text('No Coin Found'),
                      )
                          : ListView.separated(
                        itemCount: listCoin.length,
                        itemBuilder: (context, index) {
                          return _buildCoin(listCoin[index]);
                        },
                        separatorBuilder: (context, index) => Divider(),
                      ),
                    ),
                  ],
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Center(child: Text('Error Occurred'));
              }
            },
          ),
        ),
      ),

    );
  }

  Padding _buildCoin(CoinModel coin) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailPage(coin: coin)));
        },
        leading: Image.network(
          coin.image ?? '',
          width: 50,
          height: 50,
        ),
        title: Text(coin.name ?? ''),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyHelper.idr(coin.currentPrice!),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              '${coin.priceChangePercentage24h ?? 0.0} %', // Default to 0.0 if null
              style: TextStyle(
                color: (coin.priceChangePercentage24h ?? 0.0) < 0
                    ? Colors.red // If negative, set color to green
                    : Colors.green,  // If positive or 0, set color to red
              ),
            )
          ],
        ),
      ),
    );
  }


  }


