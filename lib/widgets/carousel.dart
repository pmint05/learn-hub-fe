import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

class Carousel extends StatefulWidget {
  const Carousel({super.key});

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  int selectedDot = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          spacing: 10,
          children: [
            SizedBox(
              height: 110,
              child: OverflowBox(
                maxWidth: MediaQuery.of(context).size.width,
                child: MoonCarousel(
                  physics: BouncingScrollPhysics(),
                  anchor: 0,
                  isCentered: true,
                  itemCount: 10,
                  itemExtent: 110,
                  itemBuilder:
                      (BuildContext context, int itemIndex, int _) => Container(
                        decoration: ShapeDecoration(
                          color: Colors.black12,
                          shape: MoonSquircleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ).squircleBorderRadius(context),
                          ),
                        ),
                        child: Center(child: Text("${itemIndex + 1}")),
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
