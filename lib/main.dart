import 'package:flutter/material.dart';

void main() => runApp(MyApp());

double borderRadius = 30;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          backgroundColor: Colors.black,
          primarySwatch: Colors.blue,
        ),
        home: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            child: NavDrawer()));
  }
}

Map<String, Widget> navMenuItems = Map()
  ..putIfAbsent(
      "Home",
          () => Page("Home",
          "https://images.saatchiart.com/saatchi/927428/art/4515977/3585817-WZEPJOJM-7.jpg"))
  ..putIfAbsent(
      "Furniture",
          () => Page("Furniture",
          "https://cdn.shopify.com/s/files/1/1083/5404/products/101606_1024x1024.jpg?v=1479668978"))
  ..putIfAbsent(
      "Delivery",
          () => Page("Furniture",
          "https://images1.novica.net/pictures/27/p345037_2a.jpg"));

class NavDrawer extends StatefulWidget {
  @override
  State createState() => _NavDrawerState();
}

class _NavDrawerState extends State<StatefulWidget>
    with SingleTickerProviderStateMixin {
  var currentPageKey = "Home";
  var oldPageKey = "Home";
  var changingPages = false;
  var position = 0.0; //0 is closed, 1 is open;
  AnimationController
  controller; //forward opens the drawer, backwards closes it
  Animation<double> animation;
  Function toggleDrawer;
  Function changePage;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    final Animation ease =
    CurvedAnimation(parent: controller, curve: Curves.easeInOutSine);
    animation = Tween<double>(begin: 0, end: 1).animate(ease)
      ..addListener(() {
        setState(() {
          position = animation.value;
        });
        if (animation.value == 0) {
          setState(() {
            changingPages = false;
          });
        }
      });

    toggleDrawer = () {
      if (animation.value > 0) {
        controller.reverse();
      } else {
        controller.forward();
      }
    };

    changePage = (String newPageKey) {
      if (newPageKey == currentPageKey) {
        toggleDrawer(); //make no changes;
      } else {
        setState(() {
          changingPages = true;
          oldPageKey = currentPageKey;
          currentPageKey = newPageKey;
        });
        controller.reverse();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    var currentPageWidget = navMenuItems[currentPageKey];
    var leavingPageWidget = navMenuItems[oldPageKey];
    return Scaffold(
        body: DrawerControls(
            toggleDrawer: toggleDrawer,
            changePage: changePage,
            child: Stack(fit: StackFit.expand, children: <Widget>[
            Image.asset("assets/menu-background.png", fit: BoxFit.cover),
            SafeArea(child: NavMenuColumn()),
            if (!changingPages)
        CurrentPageTransform(animation.value, child: currentPageWidget)
    else ...[
    NewPageEnteringTransform(animation.value,
    child: currentPageWidget),
    OldPageLeavingTransform(animation.value,
    child: leavingPageWidget),
    ]
    ])),
    );
  }
}

class CurrentPageTransform extends StatelessWidget {
  final double delta;
  final child;

  CurrentPageTransform(this.delta, {this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: Offset(180 * delta, 0),
        child: Transform.rotate(
            angle: -10 / 180 * 3.14 * delta,
            child: Transform.scale(scale: 1 - 0.2 * delta, child: child)));
  }
}

class OldPageLeavingTransform extends StatelessWidget {
  final double delta;
  final child;

  OldPageLeavingTransform(this.delta, {this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: Offset(180 + (1 - delta) * 500, 0),
        child: Transform.rotate(
            angle: -10 / 180 * 3.14,
            child:
            Transform.scale(scale: 0.8 - 0.3 * (1 - delta), child: child)));
  }
}

class NewPageEnteringTransform extends StatelessWidget {
  final delta;
  var child;

  NewPageEnteringTransform(this.delta, {this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: Offset(500 * delta, 0),
        child: Transform.rotate(
            angle: -10 / 180 * 3.14 * delta,
            child: Transform.scale(scale: 1 - 0.2 * delta, child: child)));
  }
}

class NavMenuColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage("https://images.pexels.com/photos/736716/pexels-photo-736716.jpeg"),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          child: Text(
            "John Wink",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        ...navMenuItems.entries.map((entry) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          DrawerControls.of(context).changePage(entry.key);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            entry.key,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }).toList()
    ]),
    );
    }
}

class DrawerControls extends InheritedWidget {
  final Function toggleDrawer;
  final Function changePage;

  DrawerControls({this.toggleDrawer, this.changePage, Widget child})
      : super(child: child);

  static DrawerControls of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DrawerControls>();

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;
}

class Page extends StatelessWidget {
  final String title;
  final String imageUrl;

  Page(this.title, this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70), blurRadius: 20.0,
              // has the effect of softening the shadow
              spreadRadius: 2.0,
              // has the effect of extending the shadow)
            )
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
//            Image.network(imageUrl, fit: BoxFit.cover),
            Image.asset("assets/foreground.png", fit: BoxFit.cover),
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                DrawerControls.of(context).toggleDrawer();
              },
            )
          ],
        ),
      ),
    );
  }
}
