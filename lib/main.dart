import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'model/passengers_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;
  late int totalPages;
  List<Passenger> passengers = [];
  final RefreshController refreshController =
      RefreshController(initialRefresh: true);

  Future<bool> getPassengerData({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 0;
    } else {
      if (currentPage >= totalPages) {
        refreshController.loadNoData();
        return false;
      }
    }

    final Uri url = Uri.parse(
        'https://api.instantwebtools.net/v1/passenger?page=$currentPage&size=10');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final result = passengersDataFromJson(response.body);

      if (isRefresh) {
        passengers = result.data;
      } else {
        passengers.addAll(result.data);
      }

      currentPage++;
      totalPages = result.totalPages;
      print(response.body);
      setState(() {});
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite List Pagination'),
      ),
      body: SmartRefresher(
        controller: refreshController,
        enablePullUp: true,
        onRefresh: () async {
          final result = await getPassengerData(isRefresh: true);
          if (result) {
            refreshController.refreshCompleted();
          } else {
            refreshController.refreshFailed();
          }
        },
        onLoading: () async {
          final result = await getPassengerData();
          if (result) {
            refreshController.loadComplete();
          } else {
            refreshController.loadFailed();
          }
        },
        child: ListView.separated(
            itemBuilder: (context, index) {
              final passenger = passengers[index];
              return ListTile(
                title: Text(passenger.name),
                subtitle: Text(passenger.airline.first.country),
                trailing: Text(passenger.airline.first.name),
              );
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: passengers.length),
      ),
    );
  }
}
