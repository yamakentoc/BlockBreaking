
//1016187 山口賢登


//圧縮ファイルをすべて展開してください。
//注意　デフォルトの状態だと実行できません。
//メニューバーのスケッチ→ライブラリをインポート→ライブラリを追加→「Minim」と検索→「Minim | An audio library...」をインストール
//メニューバーのスケッチ→ライブラリをインポート→ライブラリを追加→「Video」と検索→と検索→「Video | GStreamer-based video...」をインストール
//インストールに時間がかかる場合があります。
//メニューバーのスケッチ→ライブラリをインポート「Video」と「Minim」をクリック
//これで実行できます。


import ddf.minim.*; //minimライブラリのインポート
Minim minim;  //Minim型変数であるminimの宣言
AudioPlayer player;  //サウンドデータ格納用の変数
AudioInput in; //音入力オブジェクト用変数←(2)


float volumeIn; //入力値×1000
float e; //声の大きさ

float sa; //入力値×1000と今の大きさとの差
float easing = 0.1; //イージングの係数、大きい数値は大きく変化

import processing.video.*;//ビデオライブラリのインポート
Capture video;// ライブカメラの映像をあつかうCapture型の変数
int w=640;
int h=480;         

int musicnumber =1;  //効果音をかける回数
int game=0;          //gameの初期値を０に設定
boolean flag=true;                        //ゲームの続行に関する部分;
boolean pause=false;                      //ポーズ機能


int[] pix=new int[w*h];

color[] exColor=new color[w*h];    //前回画面ピクセル色を保存するための配列を用意


float vx, vy;    //動態検知によって得たx,y座標
float m=320;     //スタート画面の■をx=320の位置に置く
float n=240;     //スタート画面の■をy=240の位置に置く

int sumX, sumY;                //平均値を求めるための合計座標値の変数
int pixelNum;                  //変化のあったピクセルを数えるための変数
boolean movement=false;        //動体の有無のフラグ
int tolerance=48;



float block_w=60, block_h=20.0;          //ブロックの縦横
float ball_x=10, ball_y=100;               //ボールの中心のx,y座標
float ball_w=10, ball_h=10;                //ボールの縦横のおおきさ
float ball_dx=2, ball_dy=4;                //ボールのx,y座標の変化量
float ra_x, ra_y;                        //打ち返す棒の左上の座標
int hit[]=new int[48];
int block_hp=1;                         //何回当たって壊れるか

int checkHitBlock(int n, int h, float x, float y) {          //ボールがどうなったときブロックに当たったことになるか
  float left=block_w*n;              //ブロックの左側
  float right=block_w*(n + 1);       //ブロックの右側
  float top=48*h;                    //ブロックの上
  float bottom=48+block_h*h;         //ブロックの下
  float dx, dy;                      //ブロックのxの向き、yの向き

  if ((x+ball_w-5<left)||(x-5>=right)||(y+ball_h+5<top)||(y-5>=bottom)) {
    return 0;                        //ブロックの当たり判定
  }  
  if (x+ball_w-left>right-x) {
    dx=right-x;                      //xの向きを変える
  } else {
    dx=x+ball_w-left;                //xの向きを変える
  }
  if (y+ball_h-top>bottom-y) {       //yの向きを変える
    dy=bottom-y;
  } else {
    dy=y+ball_h-top;                 //yの向きを変える
  }
  if (dx>dy) {                       //xの向きがyより大きいとき
    return 1;                       //１を返す
  } else {
    return 2;                        //２を返す
  }
}

void keyPressed() {

  if (keyCode==CONTROL) {
    pause=true;                      //CONTROLを押すとpause画面に移る
  } else if (keyCode==SHIFT) {
    pause=false;               //SHIFTを押すとpause画面から戻る
  }}
  
  
void mousePressed() {
  game = 0;           //マウスをクリックするとスタート画面に移る
}


void stop()
{
  player.close();  //サウンドデータを終了
  minim.stop();    //Minimオブジェクトをクリア
  super.stop();
}

void setup() {
  size(640, 480);
  frameRate(50);

  video = new Capture(this, w, h);     //画面サイズのキャプチャ画像を生成

  video.start();                       //カメラ(ビデオ)を再生


  noStroke();
  for (int block=0; block<hit.length; block++) {
    hit[block]=block_hp;                       //それぞれのblockにblock_hpを置く
  }
  minim = new Minim(this);                 //初期化
  player = minim.loadFile("coin05.mp3");  //groove.mp3をロードする

  minim = new Minim(this);                 //Minin生成
  
  in = minim.getLineIn(Minim.MONO, 512);   //AudioInputオブジェクト生成
}



void show_block(int n1, int n2) {                  //returnなど返ってくる値がないときvoid
  stroke(0);
  fill(255, 0, 0);
  rect(block_w*n1, block_h*n2, block_w, block_h);   //ブロックを表示
}










void draw() {

  switch(game) {
  case 0:                           //case 0のとき




    if (video.available()) {        //もしキャプチャができたら
      video.read();                 //ビデオフレームの読み込み
      set(0, 0, video);             //カメラ映像を表示

      scale(-1, 1);//画面を鏡像（左右反転）                   
      image(video, -w, 0);//鏡像のため映像のX座標を-wにして表示 
      scale(-1, 1);//鏡像を戻しておく                         

      loadPixels();         //画面に画像のピクセルを展開

      movement=false;                                                           //動体有りのフラグをfalseにしておく
      for (int i=0; i<w*h; i++) {     
        float difRed=abs(red(exColor[i])-red(video.pixels[i]));               //前回と今回の画面のピクセルの各色の差を求める
        float difGreen=abs(green(exColor[i])-green(video.pixels[i]));
        float difBlue=abs(blue(exColor[i])-blue(video.pixels[i]));

        if (difRed>tolerance && difGreen>tolerance && difBlue>tolerance) {    //色の差がある場合(動態があるとき)
          movement=true;                                                      //動体有りのフラグをtrueにしておく

          sumX+=i%w;         //平均値を求めるためにX座標値を加算する
          sumY+=i/w;         //平均値を求めるためにY座標値を加算する
          pixelNum++;        //変化のあったピクセル数を数える
        }
        exColor[i]=video.pixels[i];      //次回ループのために今回の画面を前回の画面として保存しておく
      }

      for (int block=0; block<hit.length; block++) {
        hit[block]=block_hp;
      }
      updatePixels();
      if (movement==true) {     //動体があった場合
        m=sumX/pixelNum;         //X座標平均値を求める
        n=sumY/pixelNum;         //Y座標平均値を求める
        sumX=0;
        sumY=0;
        pixelNum=0;
      }
    } 




    fill(255, 0, 0);
    rect(width-m, n, 20, 20);    //動態があったときのx座標を反対側に表示(そうじゃないと鏡状態に■を表示できない)
    fill(0, 40, 255);

    if (width-m<=100) {          //画面左端から50以下に■をもっていくとgame=1に移行する
      game=1;
    }
    if (width-m>=550) {         //画面右端から600以上に■を持っていくとgame=2に移行する
      game=2;
    }

    fill(0);
    rect(0, 0, 100, 480);        //画面左側の文字の背景を黒にする
    rect(550, 0, 90, 480);       //画面右側の文字の背景を黒にする


    textSize(70);
    fill(255, 255, 0);
    text("move", 320, 100);           //スタート画面の指示　
    text("left or right", 330, 200);
    fill(255);


    textAlign(CENTER);   //テキストを真ん中に表示 
    text("c", 50, 70);   //camera を縦に表示
    text("a", 50, 150);  //("",x,y,w,h)を使用したがうまくいかなかったためこのようにした
    text("m", 50, 230);
    text("e", 50, 310);
    text("r", 50, 390);
    text("a", 50, 470);

    text("v", 600, 90);
    text("o", 600, 180);
    text("i", 600, 270);
    text("c", 600, 350);
    text("e", 600, 440);



    ball_x=10;        //ボールの初期位置の設定
    ball_y=100;


    break;



  case 1:                                      //cameraゲームの場合

    if (flag==true&&pause==false) {            //GAME OVERではなく、pauseではない場合

      if (video.available()) {                 //もしキャプチャができたら

        background(0);
        video.read();                           //ビデオフレームの読み込み


  volumeIn = map(in.left.level(), 0, 0.5, 0, width*2);     //AudioInputオブジェクトから音量を取得、入力値(0から0.5)を0から500に換算
      sa=volumeIn - e;                                         //入力値と今の声の大きさとの差
      if (abs(sa) > 1) { //差の絶対値が1より大きい時だけ大きさを変える
        e = e + sa * easing; //差の0.1分ずつ変化
      }
     


        set(0, 0, video);
        scale(-1, 1);//画面を鏡像（左右反転）
        image(video, -w, 0);//鏡像のため映像のX座標を-wにして表示
        scale(-1, 1);//鏡像を戻しておく



        loadPixels();        //画面に画像のピクセルを読み込む




        movement=false;
        for (int i=0; i<w*h; i++) {     
          float difRed=abs(red(exColor[i])-red(video.pixels[i]));             //前回と今回の画面のピクセルの各色の差を求める
          float difGreen=abs(green(exColor[i])-green(video.pixels[i]));
          float difBlue=abs(blue(exColor[i])-blue(video.pixels[i]));

          if (difRed>tolerance && difGreen>tolerance && difBlue>tolerance) {    //色の差がある場合(動態があるとき)
            movement=true;                                                       //動体有りのフラグをtrueにしておく
           
            sumX+=i%w;                                                        //平均値を求めるためにX座標値を加算する
            sumY+=i/w;                                                        //平均値を求めるためにY座標値を加算する
            pixelNum++;                                                       //変化のあったピクセル数を数える
          }

          exColor[i]=video.pixels[i];                                        //次回ループのために今回の画面を前回の画面として保存しておく
        }
        updatePixels();                    //画面に画像のピクセルを展開
        if (movement==true) {                         //動体有りのフラグがtrueのとき
          vx=sumX/pixelNum;                           //動態検知によって得たx座標を求める
          vy=sumY/pixelNum;                           //動態検知によって得たy座標を求める
          sumX=0;                                      
          sumY=0;                                      //平均値を求めるための合計座標値を0にする
          pixelNum=0;                                //ピクセル数を0にする
        }







        noStroke();
        fill(255, 0, 0);
        ellipse(ball_x, ball_y, ball_w, ball_h); //ボールの描画
        ball_x+=ball_dx;                      //ボールの動く速さ(x座標)
        ball_y+=ball_dy;                      //ボールの動く速さ(y座標)
        if (ball_x+5>=width||ball_x-5<=0) {     //左右の壁にボールが当たった時跳ね返る
          ball_dx*=-1;
        }
        if (ball_y-5<=0) {                      //天井にボールが当たった時跳ね返る
          ball_dy*=-1;
        }
        if (vx>width-25) {                  //ボールが右側の壁に当たったときの処理
          ra_x=width-50;
        } else if (vx<25) {                //ボールが左側の壁に当たったときの処理
          ra_x=0;
        } else {
          ra_x=vx-25;
        }
        ra_y=height-48;                     //ラケットの高さを設定
        rect(w-vx, ra_y, 50, 5);            //ラケットを配置する



        if (ball_y+5>=ra_y&&ball_y+5<=ra_y+50&&ball_x>=(w-vx)&&ball_x<=(w-vx)+50) {        //ラケットとボールが当たったときの処理
          ball_dy*=-1;
        }

        for (int i=0; i<12; i++) {                     
          for (int j=0; j<hit.length/12; j++) {                          //ボールがブロックに当たったときの処理
            if (hit[j*12+i]>0) {
              show_block(i, j);                                         //ブロックの表示
              switch(checkHitBlock(i, j-1, ball_x, ball_y)) {           //当たり判定のそれぞれの処理
              case 1:                                                   //case 1のとき
                ball_dy*=-1;                                            //ボールのy座標をマイナスにする
                hit[j*12+i]--;                                          
                player.play();                                          //再生
                player.rewind();                                        //再生が終わったら巻き戻しておく
                break;
              case 2:                                                   //case 2のとき
                ball_dx*=-1; 
                hit[j*12+i]--;
                player.play();                                          //再生
                player.rewind();                                         //再生が終わったら巻き戻しておく
                break;
              }
            }
          }
        }

        if (ball_y>=height) {      //ボールを撮り損ねたらゲームオーバーの処理に移行
          
           if(e>150){
             e=151;
        game=0;
      }
          
          textSize(100);
          fill(255, 255, 0);
          text("GAME OVER", 330, 300);         //GAME OVER の表示
          while ( musicnumber<=2) {            //musicnumberが２以下の時{}内を実行
            musicnumber=musicnumber+1;         //misicnumberを+1する
            minim = new Minim(this);            //Minin生成
            player = minim.loadFile("blip04.mp3");//blip04.mp3をロードする
            player.play();                      //再生
          }
        }
      }
    }
    if (pause==true) {                          //もしpauseの時
      textSize(100);
      fill(255, 0, 0);
      text("pause", 330, 250);                 //pauseを表示
    }

    break;




  case 2:                                        //voiceゲームの場合
    if (flag==true&&pause==false) {            //GAME OVERではなく、pauseではない場合
      background(0);
      noStroke();
      fill(255, 0, 0);
      ellipse(ball_x, ball_y, ball_w, ball_h); //ボールの描画
      ball_x+=ball_dx;                      //ボールの動く速さ(x座標)
      ball_y+=ball_dy;                      //ボールの動く速さ(y座標)




      if (ball_x+5>=width||ball_x-5<=0) {     //左右の壁にボールが当たった時跳ね返る
        ball_dx*=-1;
      }
      if (ball_y-5<=0) {                      //天井にボールが当たった時跳ね返る
        ball_dy*=-1;
      }
      if (e>width-25) {                       //ボールが右側の壁に当たったときの処理
        e=width-50;
      } else if (e<25) {                      //ボールが左側の壁に当たったときの処理
        ra_x=0;
      } else {
        ra_x=ball_x-25;
      }
      ra_y=height-48;                         //ラケットの高さを設定


      volumeIn = map(in.left.level(), 0, 0.5, 0, width*2);     //AudioInputオブジェクトから音量を取得、入力値(0から0.5)を0から500に換算
      sa=volumeIn - e;                                         //入力値と今の声の大きさとの差
      if (abs(sa) > 1) { //差の絶対値が1より大きい時だけ大きさを変える
        e = e + sa * easing; //差の0.1分ずつ変化
      }

      if (e>300) {                                           //声の大きさが250以上のとき
        for (int i=0; i < 400; i++) {
          fill(255, 0, 0); // 塗りつぶしの色をランダムに決める
          float size = random(10, 10); 
          ellipse(random(width), random(height), size, size); // ランダムな位置に円を描画
        }
      }

      rect(e, ra_y, 100, 5);                                    //声の大きさによってラケットのx座標が変わるラケット

      if (ball_y+5>=ra_y&&ball_y+5<=ra_y+100&&ball_x>=e&&ball_x<=e+100) {     //ボールがラケットに当たったときの処理
        ball_dy*=-1;
      }

      for (int i=0; i<12; i++) {
        for (int j=0; j<hit.length/10; j++) {                             //ボールがブロックに当たったときの処理
          if (hit[j*12+i]>0) {
            show_block(i, j);                                             //ブロックの表示
            switch(checkHitBlock(i, j-1, ball_x, ball_y)) {               //当たり判定のそれぞれの処理
            case 1:                                                     //case 1のとき
              ball_dy*=-1;
              hit[j*12+i]--;
              break;
            case 2:                                                     //case 2のとき
              ball_dx*=-1;
              hit[j*12+i]--;
              break;
            }
          }
        }
      }


      if (ball_y>=height) {                   //ボールを撮り損ねたらゲームオーバーの処理に移行
        
         if(e>150){
           e=151;
        game=0;
      }
        
        textSize(100);
        fill(255, 255, 0);
        text("GAME OVER", 320, 300);        //GAME OVERを表示
      }
      if (pause==true) {                      //pauseのとき
        textSize(100);
        fill(255, 0, 0);
        text("pause", 150, 250);            //pauseを表示
      }


      break;
    }
  }
}