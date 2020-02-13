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
  var changingPages =
      false; //we're in a "changing pages" state whenever we're animating from one page to another
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
        duration: const Duration(milliseconds: 1300),
        vsync: this); //this is super long just to show the animation
    final Animation ease = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutSine); //animation curve looked nice
    animation = Tween<double>(begin: 0, end: 1).animate(ease)
      ..addListener(() {
        setState(() {
          position = animation.value;
        });
        if (animation.value == 0) {
          setState(() {
            changingPages = false; //
          });
        }
      });

    toggleDrawer = () {
      if (animation.value > 0) {
        controller.reverse(); //animate from 1 (open state) to 0 (closed state)
      } else {
        controller.forward(); //animate from 0 (closed state) to 1 (open state)
      }
    };

    changePage = (String newPageKey) {
      if (newPageKey == currentPageKey) {
        toggleDrawer(); //make no changes
      } else {
        setState(() {
          changingPages = true;
          oldPageKey = currentPageKey;
          currentPageKey = newPageKey;
        });
        controller.reverse(); //animate from 1 (open state) to 0 (closed state)
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPageWidget = navMenuItems[currentPageKey](animation.value);
    Widget leavingPageWidget = navMenuItems[oldPageKey](animation.value);
    return Scaffold(
      body: DrawerControls(//this drawerControls inherited widget means anything
        //in this hierarchy can grab the functions we declared above (toggle, changePage)
        //and call them
          toggleDrawer: toggleDrawer,
          changePage: changePage,
          child: Stack(fit: StackFit.expand, children: <Widget>[
            Image.asset("assets/menu-background.png", fit: BoxFit.cover),
            SafeArea(child: NavMenuColumn()),
            //this is kinda weird here, but i like how it fits together.
            //basically, if we're not changing pages, we only need to show one page
            //so show that page with the appropriate transform for our current animation
            //state

            //if we're animating, however, we need to show both the incoming and outgoing
            //pages. So, show those instead, with the appropriate transforms for our
            //current animation state

            //I think these might need keys, so as we switch from one state to the other,
            //flutter can "recycle" the widgets appropriately, but im not an expert on all that
            //and performance seems fine regardless.
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

//this transforms its child based on delta (our 0 to 1 animation state)
//when at 0 (closed state), this doesn't transform the page at all
//when it's at 1 (fully open state), this moves it off to the right, rotates it a bit, and scales it down
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

//this transforms the leaving page
//as the animation goes from 1->0 (closing the drawer)
//but I like thinking in terms of animating from 0 to 1, so I use invertedDelta instead
//in this case, an invertedDelta of 0 is our "fully open" (see above) state, and 1 is our "off-screen" state
//the page should go from the above "fully open" transform state to an off-screen state.
class OldPageLeavingTransform extends StatelessWidget {
  final double delta;
  final child;

  OldPageLeavingTransform(this.delta, {this.child});

  @override
  Widget build(BuildContext context) {
    var invertedDelta = 1 - delta;
    return Transform.translate(
        offset: Offset(fullyOpenTranslationX + invertedDelta * 500, 0),
        child: Transform.rotate(
            angle: fullyOpenRotation,
            child:
                //this 0.8 here is the equivalent of a "fully open" scale in the CurrentPageTransform.
                //specifically, we're going from that 0.8 "fully open" at our 0-starting state to 0.5 at the 1-offscreen state
                Transform.scale(
                    scale: 0.8 - 0.3 * invertedDelta, child: child)));
  }
}

//as the animation goes from 1 to 0, we go from off-screen to the "closed" state with no transform
class NewPageEnteringTransform extends StatelessWidget {
  final delta;
  final child;

  NewPageEnteringTransform(this.delta, {this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        offset: Offset(500 * delta, 0),
        //goes from 500 pixels to the right at 1 to 0 pixels (no transform) at the 0
        child: Transform.rotate(
            angle: fullyOpenRotation * delta,
            child: Transform.scale(scale: 1 - 0.2 * delta, child: child)));
  }
}

//this is just a generic nav menu, nothing crazy here.
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
            //in this case, we're taking all our nav menu items
            //and we're mapping each item to a button that's going to represent it in our nav menu
            //when the user taps one, it tells drawerControls to switch to that page, triggering all our animations
        //then, take all those buttons we made and dump them in-line into this column we've got with
        //this fancy ... operator
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

//this class just holds all the methods for interacting with the drawer.
//any widget below this in the hierarchy can call these methods to open/close the
//drawer or change the currently displayed page. (though, it's worth noting that
//the animation for changing only works if the drawer is open. definitely possible to
//fix that though)
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
              //specifically, if drawerDelta is greater than 0, the drawer is open, and the shadow would be visible
              //so show it.
              //if it's equal to 0, then the drawer is closed, and the shadow would
              // be invisible, so dont add it to the decoration

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
