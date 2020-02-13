import 'package:flutter/material.dart';

void main() => runApp(MyApp());

double borderRadius = 30;

class MyApp extends StatelessWidget {
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

Map<String, Function> navMenuItems = Map()
  ..putIfAbsent(
      "Home", () => (delta) => Page("Home", "assets/foreground.png", delta))
  ..putIfAbsent("Furniture",
      () => (delta) => Page("Furniture", "assets/foreground-blue.png", delta))
  ..putIfAbsent("Delivery",
      () => (delta) => Page("Delivery", "assets/foreground-pink.png", delta));

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
        duration: const Duration(milliseconds: 800),
        vsync: this); //this is super long just to show the animation
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
    Widget currentPageWidget = navMenuItems[currentPageKey](animation.value);
    Widget leavingPageWidget = navMenuItems[oldPageKey](animation.value);
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
              OldPageLeavingTransform(animation.value,
                  child: leavingPageWidget),
              NewPageEnteringTransform(animation.value,
                  child: currentPageWidget),
            ]
          ])),
    );
  }
}

final fullyOpenTranslationX = 180;
final fullyOpenRotation = -10 / 180 * 3.14;

class CurrentPageTransform extends StatelessWidget {
  final double delta;
  final child;

  CurrentPageTransform(this.delta, {this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: Offset(fullyOpenTranslationX * delta, 0),
        child: Transform.rotate(
            angle: fullyOpenRotation * delta,
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
        offset: Offset(fullyOpenTranslationX + (1 - delta) * 500, 0),
        child: Transform.rotate(
            angle: fullyOpenRotation,
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
            angle: fullyOpenRotation * delta,
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
              backgroundImage: NetworkImage(
                  "https://images.pexels.com/photos/736716/pexels-photo-736716.jpeg"),
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
  final String image;
  final drawerDelta;

  Page(this.title, this.image, this.drawerDelta);

  @override
  Widget build(BuildContext context) {
    var whiteShadowDelta = borderRadius / 2 * drawerDelta;
    var whiteShadowOffset = Offset(-2 * whiteShadowDelta, 0);

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            if (drawerDelta > 0) ...[
              //dont draw shadows if drawer is collapsed
              BoxShadow(
                  color: Colors.black.withAlpha(70),
                  blurRadius: 20.0,
                  // has the effect of softening the shadow
                  spreadRadius: -whiteShadowDelta,
                  offset: whiteShadowOffset
                  // has the effect of extending the shadow)
                  ),
              BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  spreadRadius: -whiteShadowDelta,
                  offset: whiteShadowOffset),
              BoxShadow(
                color: Colors.black.withAlpha(70),
                blurRadius: 20.0,
                // has the effect of softening the shadow
                spreadRadius: 2,
                // has the effect of extending the shadow)
              ),
            ]
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
//            Image.network(imageUrl, fit: BoxFit.cover),
            Image.asset(image, fit: BoxFit.cover),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.menu),
                    iconSize: 40,
                    color: Colors.white,
                    padding: EdgeInsets.all(30),
                    onPressed: () {
                      DrawerControls.of(context).toggleDrawer();
                    },
                  ),
                  Padding(
                      padding: const EdgeInsets.all(30), child: PageTitle()),
                  Spacer(),
                  BottomButtons()
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var highlight = TextStyle(color: Colors.white);
    return RichText(
      text: TextSpan(
        // Note: Styles for TextSpans must be explicitly defined.
        // Child text spans will inherit styles from parent
        style: TextStyle(fontSize: 30.0, color: Colors.white.withAlpha(122)),
        children: <TextSpan>[
          TextSpan(text: 'Furniture', style: highlight),
          TextSpan(text: ' that fit\nyour '),
          TextSpan(text: 'style', style: highlight)
        ],
      ),
    );
  }
}

class BottomButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      child: Container(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              padding: EdgeInsets.all(25),
              icon: Icon(Icons.star),
            ),
            IconButton(
              padding: EdgeInsets.all(25),
              icon: Icon(Icons.shopping_cart),
            ),
            IconButton(
              padding: EdgeInsets.all(25),
              icon: Icon(Icons.person),
            )
          ],
        ),
      ),
    );
  }
}
