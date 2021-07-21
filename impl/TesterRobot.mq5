//+------------------------------------------------------------------+
//|                                                  TesterRobot.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

enum ROBOTS{
   SCALPER,
   TORETTO,
};

input ROBOTS ROBOT = SCALPER;

#include "ScalperRobot.mq5"

datetime startedDatetimeRobotTester ;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   startedDatetimeRobotTester = TimeCurrent();
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   ResultOperation res = startScalper(startedDatetimeRobotTester);
   
  }
//+------------------------------------------------------------------+
