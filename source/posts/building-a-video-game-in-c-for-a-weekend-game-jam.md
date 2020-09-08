---
title: Building a video game in C for a weekend game jam
created: 2020-04-27T00:00:00Z
description: Summary of building a video game entry for Ludum Dare 46 game jam. Top-down survival shooter in C and SDL.
keywords: c, video game, ludum dare, ludum dare 46, game engine, top-down shooter, video game game jam, SDL, game engine, game in C, video game source code
---

It was the 46th edition of Ludum Dare game jam recently. I've completed a small video game as part of the event. Here's a short write-up.

Summary:

- [**Play the game online**](https://lchsk.com/alive_game)
- [**Source code of the game**](https://github.com/lchsk/alive-game)
- [**Ludum Dare 46 page**](https://ldjam.com/events/ludum-dare/46/alive-the-game)

- [**Game play video:**](https://www.youtube.com/watch?v=RhdIpSkOQgM)

[![Alive game play video on YouTube](https://img.youtube.com/vi/RhdIpSkOQgM/0.jpg)](https://www.youtube.com/watch?v=RhdIpSkOQgM)

## The game

The theme this time was 'Keep it alive'. I have decided to consider it literally and create a survival game. The main character is being attacked by an endless wave of enemies. The player must keep him alive as long as possible (although he will eventually succumb as there's no actual way of winning).

<a href="./data/projects/alive_game_1.png"><img src="./data/projects/alive_game_1.png" alt="Alive game screenshot"/></a>

*A screenshot of the complete game*

The player controls his character by using the mouse and the keyboard. The character's movement is a bit quirky as he moves in relation to where the mouse is pointing to. For example, pressing 'W' key moves the player 'forward', i.e. towards the mouse cursor. The player can also use one of three weapons to attack his enemies.

It was the second time I have participated in Ludum Dare (previously, I've submitted a turn-based strategy game in C++ for Ludum Dare 42, see blog post: {{@making-a-turn-based-strategy-game-in-cpp-in-72-hours}}). This time, I've approached things a bit differently. I had written a small game engine in C beforehand, so I haven't started completely from scratch. The game engine is tiny and could use many new additions, but allowed me to save some time on things like loading assets and other fairly mundane tasks. My previous submission hasn't used any reusable codebase. 

The game, like the engine, is written in C. I've found C to be, perhaps counterintuitively, a better choice for a game jam than C++ (which I've used for the previous Ludum Dare). Less complexity tends to invite clearer and more obvious solutions which can be a big win if the task needs to be completed quickly. There are practical benefits, too, such as less cryptic error messages and faster compilation times.

The game can also be compiled with Emscripten and played as a game in a web browser.

<a href="./data/projects/alive_game_2.png"><img src="./data/projects/alive_game_2.png" alt="Alive game screenshot"/></a>

*A screenshot of the complete game with the welcome screen*

## Game engine

The game engine I've used for this game is pretty simple and includes just a few basics. Funnily enough, I haven't even used all the features of the engine (e.g. didn't need animations).

It is built in C on top of the SDL library and uses it for rendering, input, music, and sounds. It includes a few useful features such as loading several types of assets: textures, music, sounds, and fonts. It renders sprites and animations as well as text. It uses a simple abstraction over game objects, called entities, which can render animations, sprites, and also handle basic collisions. It also includes an in-game console which can accept input, but it hasn't been used in the game. The engine is in early stages but I'm looking forward to smoothing over some edges and adding some features to make it even more useful.

The source of the engine is [available on GitHub](https://github.com/lchsk/engine212).

## Things to improve

Considering the time limit, I'm happy with the result. However, there are a few things that would make the game a bit nicer to play. The game controls can feel a little strange. I like that it makes the game more challenging but can also see it might put people off. A somewhat annoying feature is that the player's enemies start shooting bullets even before appearing on the screen. Also, there's currently no feedback given to the player when he hits the enemy, which could be a useful improvement.

Overall, I'm happy to have managed to complete the game on time. Additionally, I enjoyed using my tiny game engine and I'm looking to improve it.
