#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>


CPositionInfo  tradePosition;                   // trade position object
CTrade tradeLib;

enum TYPE_ORDER{
   NO_ORDER,
   LIMIT,
   STOP,
   STOP_LIMIT,
};

enum TYPE_CANDLE{
   WEAK,
   STRONG,
   HAMMER,
   UNDECIDED,
};

enum OPERATOR{
   EQUAL,
   MAJOR,
   MINOR
};

enum ORIENTATION{
   UP,
   DOWN,
   MEDIUM
};

enum POSITION_GRAPHIC{
   BOTTOM,
   TOP,
   CENTER
};

enum TYPE_NEGOCIATION{
   BUY,
   SELL,
   NONE
};

enum POWER{
   ON,
   OFF
};

enum COORDINATE{
   HORIZONTAL,
   VERTICAL
};


struct CandleInfo {
   ORIENTATION orientation;
   TYPE_CANDLE type;
   double close;
   double open;
   double high;
   double low;
};

struct ResultOperation {
   double total;
   double profits;
   double losses;
   double liquidResult;
   double profitFactor;
   bool instantiated;
};

struct MainCandles {
   MqlRates actual;
   MqlRates last;
   MqlRates secondLast;
   bool instantiated;
};


struct BordersOperation {
   double max;
   double min;
   double central;
   bool instantiated;
   ORIENTATION orientation;
};

struct PeriodProtectionTime {
   string dealsLimitProtection;
   string endProtection;
   string startProtection;
   bool instantiated;
};

input double PERCENT_MARGIN_OPERATION = 10;
input bool ACTIVE_SUPORT_AND_RESISTANCE = true;
double DAILY_GOAL = 0;
input double VOL_OPERATION = 0;
TYPE_ORDER ORDER = NO_ORDER;
int ORDER_DURATION = 300;
double ORDER_LIMIT_POINT = 40;
input long DURATION_POSITION_IN_LOSS = 0;
input double  POINTS_TO_CLOSE = 0;
input double  MOVIMENT_PERMANENT = 0;
input double  PROTECT_ORDERS_BY_DURATION = 0;
input POWER  EXPONENTIAL_ROBOTS = ON;
input POWER  EXPONENTIAL_VOLUME = ON;
POWER  COUNT_ACTIVE_LOCK = OFF;
input POWER  ACTIVE_MOVE_TAKE = ON;
input POWER  ACTIVE_MOVE_STOP = ON;
input POWER  CALCULATE_MARGIN = ON;
input POWER  PROTECT_ALL = ON;
input POWER  ACTIVE_MOVE_TO_ZERO_IN_NEW_CANDLE = OFF;
input POWER  CLOSE_IN_MIN_OR_MAX = OFF;
input double PERCENT_MOVE = 40;
input double PONTUATION_MOVE_STOP = 400;
input ulong MAGIC_NUMBER = 3232131231231231;
input int NUMBER_ROBOTS = 10;
input int NUMBER_MAX_ROBOTS = 60;
input int COUNT_TICKS = 120;
input double TAKE_PROFIT = 1000;
input double STOP_LOSS = 1000;
input double VOLUME = 0.01;
input int PERIOD_ROBOT = 13;
input double MIN_BALANCE = 0;
input string START_TIME = "01:30";
input string END_TIME = "23:20";
input POWER IGNORE_MAGIC =  OFF;
input ENUM_TIMEFRAMES TIME_FRAME = PERIOD_M5;
input int NUMBER_TOPS_AND_BOTTOMS = 3;

 double CANDLE_POINTS = 300;
 
POWER  LOCK_IN_LOSS = OFF;
POWER USE_MAGIC_NUMBER = ON;
double PONTUATION_ESTIMATE = 500;
int NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
double ACTIVE_VOLUME = VOLUME;

struct TopsAndBottoms {
   double tops[];
   double bottoms[];
};


MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 

ORIENTATION orientMacro = MEDIUM;
int periodAval = 4, countRobots = 0, countTicks = 0   , countCandles = 0;
int WAIT_NEW_CANDLE = 0;
ulong robots[];

MqlRates candleMacro;
double averages[], averages8[], averages20[], averages80[], averages200[], MACD[], MACD5[], CCI[], FI[], VOL[], STHO1[],STHO2[], pointsMacro = 0;
double upperBand[], middleBand[], lowerBand[], upperBand5[], middleBand5[], lowerBand5[], RVI1[], RVI2[], RSI[];
int handleaverages[10], handleBand[2] ,handleICCI, handleVol, handleMACD, handleIRVI, handleFI, handleIRSI, handleStho;

int MULTIPLIER_ROBOTS = 2;
double BALANCE_ACTIVE = 0, INITIAL_BALANCE = 0, INITIAL_INVESTIMENT_ACTIVE = 0, INITIAL_INVESTIMENT = 0;
ORIENTATION bestOrientation = MEDIUM, orientMACD = MEDIUM, orientAv = MEDIUM, orientRVI = MEDIUM;
POWER lockBuy = OFF, lockSell = OFF;
int countLockBuy = 0, countLockSell = 0;
int countBuy = 0, countSell = 0, countSellBackup, countBuyBackup;
double EXPONENTIAL_VOLUME_ITERATOR = 100;
bool LOCK_ROBOTS = false, moveToZero = false;
int qtdBuyers = 0,  qtdBuyersWon = 0, qtdSellers = 0, qtdSellersWon = 0, qtdSellersLoss = 0, qtdBuyersLoss = 0;
double saldoAtual = 0;
datetime diaAtual = 0;   
double profitBuy = 0;
double profitSell = 0;
TopsAndBottoms topsAndBottoms;
bool firstTime = true;

  // tipo de função
int                  fast_ema_period=12;        // período da Média Móvel Rápida
int                  slow_ema_period=26;        // período da Média Móvel Lenta
int                  signal_period=9;           // período da diferença entre as médias móveis
ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE;
            
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "btnCloseBuy"){
         closeAllPositionsByType(POSITION_TYPE_BUY, 0);
      }
      if(sparam == "btnCloseSell"){
         closeAllPositionsByType(POSITION_TYPE_SELL, 0);
      }
      
      if(sparam == "btnCloseAll"){
         closeAll();
         closeOrdersByDuration(0);
      }
      if(sparam == "btnMoveStop"){
         protectPositions(15);
      }
      if(sparam == "btnBuy"){
         ulong magic = MAGIC_NUMBER + 6000;
         for(int i = 0; i < NUMBER_ROBOTS; i++){
            magic = magic + i;
            realizeDeals(BUY, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT, MAGIC_NUMBER);
         }
      }
      if(sparam == "btnSell"){
         ulong magic = MAGIC_NUMBER + 6000;
         for(int i = 0; i < NUMBER_ROBOTS; i++){
            magic = magic + i;
            realizeDeals(SELL, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT, MAGIC_NUMBER);
         }
      }
      
      if(sparam == "btnCloseProfit"){
         closePositionInProfit();
      }
      if(sparam == "btnLockBuy"){
         if(lockBuy == ON){
            lockBuy = OFF;
         }else{
            lockBuy = ON;
         }
         generateButtons();
      }
      if(sparam == "btnLockSell"){
         if(lockSell == ON){
            lockSell = OFF;
         }else{
            lockSell = ON;
         }
         generateButtons();
      }
      
      if(sparam == "btnDoubleVol"){
         ACTIVE_VOLUME *= 2;   
      }
      
      if(sparam == "btnDivVol"){
         ACTIVE_VOLUME /= 2; 
         if(ACTIVE_VOLUME < VOLUME) {
            ACTIVE_VOLUME = VOLUME; 
         } 
      }
      
      if(sparam == "btnResetVol"){
         ACTIVE_VOLUME = VOLUME; 
      }
      
      if(sparam == "btnLockRobots"){
         LOCK_ROBOTS = !LOCK_ROBOTS; 
         generateButtons();
      }
      
      if(sparam == "moveToPrice"){
          protectPositions(0, true);
      }
      
     /* if(sparam == "btnUpTakeBuy"){
         moveTakePerPoint(POSITION_TYPE_BUY, 100);
      }
      
      if(sparam == "btnDownTakeBuy"){
         moveTakePerPoint(POSITION_TYPE_BUY, -100);
      }
      
      if(sparam == "btnUpStopBuy"){
         moveStopPerPoint(POSITION_TYPE_BUY, 100);
      }
      
      if(sparam == "btnDownStopBuy"){
         moveStopPerPoint(POSITION_TYPE_BUY, -100);
      }
      
      if(sparam == "btnUpTakeSell"){
         moveTakePerPoint(POSITION_TYPE_SELL, -100);
      }
      
      if(sparam == "btnDownTakeSell"){
         moveTakePerPoint(POSITION_TYPE_SELL, 100);
      }
      
      if(sparam == "btnUpStopSell"){
         moveStopPerPoint(POSITION_TYPE_SELL, -100);
      }
      
      if(sparam == "btnDownStopSell"){
         moveStopPerPoint(POSITION_TYPE_SELL, 100);
      }*/
   }
}

int OnInit(){
      generateButtons();
      
      handleIRVI = iRVI(_Symbol,TIME_FRAME,PERIOD_ROBOT);
     // handleStho=iStochastic(_Symbol,TIME_FRAME,PERIOD_ROBOT,3,3,MODE_SMA,STO_LOWHIGH);
      //handleICCI = iCCI(_Symbol,TIME_FRAME,PERIOD_ROBOT,PRICE_TYPICAL);
      handleMACD=iMACD(_Symbol,TIME_FRAME,fast_ema_period,slow_ema_period,signal_period,applied_price);
     // handleFI = iForce(_Symbol,TIME_FRAME, PERIOD_ROBOT ,MODE_SMA,VOLUME_TICK);
      handleaverages[0] = iMA(_Symbol,TIME_FRAME, 8, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[1] = iMA(_Symbol,TIME_FRAME, 20, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[2] = iMA(_Symbol,TIME_FRAME, 80, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[3] = iMA(_Symbol,TIME_FRAME, 200, 0, MODE_SMA, PRICE_CLOSE);
      handleVol = iVolumes(_Symbol,TIME_FRAME,VOLUME_TICK);
      BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
      saldoAtual = BALANCE_ACTIVE;
      INITIAL_BALANCE = BALANCE_ACTIVE;
      INITIAL_INVESTIMENT_ACTIVE = BALANCE_ACTIVE;
      INITIAL_INVESTIMENT = BALANCE_ACTIVE;
      updateNumberRobots();
      diaAtual = TimeCurrent();
   
   
      ArrayResize(robots, NUMBER_MAX_ROBOTS + 2);
      for(int i = 0; i < NUMBER_MAX_ROBOTS; i++)  {
         robots[i] = MAGIC_NUMBER; 
      }
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
   int copiedPrice = CopyRates(_Symbol,TIME_FRAME,0,periodAval,candles);
   if(copiedPrice == periodAval){
      datetime now = TimeCurrent();
      datetime end = StringToTime(END_TIME);
      datetime start = StringToTime(START_TIME);
      if((END_TIME == START_TIME && END_TIME == "00:00") || !((now >= StringToTime("00:01") && now <= start) || (now >= end && now <= StringToTime("23:59")))){
         Print("Robôs em operação");
         double spread = candles[periodAval-1].spread;
         
         if(firstTime && ACTIVE_SUPORT_AND_RESISTANCE){
            topsAndBottoms = getMaxAndMin(NUMBER_TOPS_AND_BOTTOMS, TIME_FRAME);
            firstTime = false;
         }
         
         if(hasNewCandle()){
            moveToZero = true;
            //if(countCandles <= 0){
           //   countCandles = 5;
           if(ACTIVE_SUPORT_AND_RESISTANCE){
               topsAndBottoms = getMaxAndMin(NUMBER_TOPS_AND_BOTTOMS, TIME_FRAME);
           }
            //}
            WAIT_NEW_CANDLE--;
            countCandles--;
         }else{
            //if(verifyIfShadowBiggerThanBody(candles[periodAval-1], POINTS_MIN_CANDLE)){
             //  countTicks = COUNT_TICKS;
            //}
            
            double investiment = MathAbs(saldoAtual-INITIAL_INVESTIMENT);
            if(DAILY_GOAL <= 0 || (investiment <= DAILY_GOAL)){
               if(BALANCE_ACTIVE > MIN_BALANCE){
                  if(LOCK_ROBOTS == false){
                     if(WAIT_NEW_CANDLE <= 0){
                        Print("Executing ..");
                        if(countTicks <= 0){
                          toNegociate(spread);
                           countTicks = COUNT_TICKS;
                           moveAllPositions(spread);
                        }
                        
                        if(COUNT_ACTIVE_LOCK == ON){
                           if(countLockBuy <= 0){
                              COUNT_ACTIVE_LOCK = OFF;
                              lockBuy = OFF;
                           }
                           if(countLockSell <= 0){
                              COUNT_ACTIVE_LOCK = OFF;
                              lockSell = OFF;
                           }
                           countLockBuy--;
                           countLockSell--;
                        }
      
                        countTicks--;
                        detectChangeTendency();
                        updateNumberRobots();
                     }
                  }else{
                     if(ORDER != NO_ORDER){
                      closeOrdersByDuration(0);
                     }
                  } 
               }else{
                     if(ORDER != NO_ORDER){
                      closeOrdersByDuration(0);
                     }
               } 
            }else{
               closeAll();
               if(ORDER != NO_ORDER){
                closeOrdersByDuration(0);
               }
               
               int diffDay = daysDiff(diaAtual);
               if(diffDay >= 1){
                  diaAtual = TimeCurrent();
                  INITIAL_INVESTIMENT = INITIAL_INVESTIMENT + (saldoAtual-INITIAL_INVESTIMENT);
                  LOCK_ROBOTS = false;
               }else{
                  LOCK_ROBOTS = true;
               }
            }
         }
      }else{
         Print("Robôs fora de operação");
      }
      orientMACD = verifyOrientationMACD();
      orientAv = verifyOrientationAverage(candles[periodAval-1].close);
      orientRVI = verifyRVI();
      //ORIENTATION orientSTHO = verifySTHO();
      showComments();
   }
}

void showComments(){
   BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   saldoAtual = BALANCE_ACTIVE + profit;
   Comment(
         " Total de robôs Disponiveis: ", (NUMBER_MAX_ROBOTS - PositionsTotal()),
         " Total de robôs ativos: ", (PositionsTotal()), 
         " Saldo: ", DoubleToString(saldoAtual, 2),
         " Lucro Atual: ", DoubleToString(profit, 2),
         " Robôs de Compra: ", countBuy,
         " Robôs de Venda: ", countSell,
         " Compra Travada: ", verifyPower(lockBuy),
         " Venda Travada: ", verifyPower(lockSell),
         " Robôs Travados: ", LOCK_ROBOTS,
         " Volume: ", ACTIVE_VOLUME,
         " Melhor Orientação: ", verifyPeriod(bestOrientation),
         " Orientação das médias: ", verifyPeriod(orientAv),
         " Orientação RVI: ", verifyPeriod(orientRVI),
         " Orientação MACD: ", verifyPeriod(orientMACD));
        // " Orientação CCI: ", verifyPeriod(orientCCI),
         //" Orientação Stho: ", verifyPeriod(orientSTHO));
}

void updateNumberRobots(){
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
   
   if(EXPONENTIAL_VOLUME == ON){
      
     if(INITIAL_BALANCE > 0 && ((BALANCE_ACTIVE+profit) / INITIAL_BALANCE) >= MULTIPLIER_ROBOTS){
         MULTIPLIER_ROBOTS = 2 * MULTIPLIER_ROBOTS;
         INITIAL_BALANCE = BALANCE_ACTIVE+profit;
         ACTIVE_VOLUME *= 2 ;
         //NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
         
         double maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
         if(ACTIVE_VOLUME >  maxVolume){
            ACTIVE_VOLUME = maxVolume;
         }
      }
      else if((BALANCE_ACTIVE+profit) > 0 &&   INITIAL_BALANCE / (BALANCE_ACTIVE+profit) >= 2){
         MULTIPLIER_ROBOTS--;
         INITIAL_BALANCE = BALANCE_ACTIVE+profit;
         ACTIVE_VOLUME /= 2 ;
        // NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
         
         if(ACTIVE_VOLUME <  VOLUME){
            ACTIVE_VOLUME = VOLUME;
         }
      }/**/ 
      
     /* if(INITIAL_BALANCE >= INITIAL_INVESTIMENT_ACTIVE * NUMBER_ROBOTS){
         //ACTIVE_VOLUME = VOLUME;
         NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS_ACTIVE + NUMBER_ROBOTS ;
         NUMBER_MAX_ROBOTS_ACTIVE += NUMBER_ROBOTS;
         INITIAL_INVESTIMENT_ACTIVE = INITIAL_BALANCE;
      }*/
      
   }
   
   if(EXPONENTIAL_ROBOTS == ON){  
      if(profit > 0 || (profitBuy > 0 && countSell > 0 &&  (countBuy/countSell) <= 1) || (profitSell > 0 && countBuy > 0 &&  (countSell/countBuy) <= 1)){
         if(NUMBER_MAX_ROBOTS > NUMBER_ROBOTS_ACTIVE +  1){
            NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS_ACTIVE++;
            Print("Adicionando novos robos: " + IntegerToString(NUMBER_ROBOTS_ACTIVE));
         }else{
            EXPONENTIAL_VOLUME_ITERATOR = 100;
            Print("Maximo de robôs permitidos ");
            
         }
      }
    /*   else if(profit < 1 && (MathAbs(profit) >  (INITIAL_INVESTIMENT_ACTIVE * ACTIVE_VOLUME))){
         // NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS_ACTIVE - NUMBER_ROBOTS ;
           NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
          Print("Removendo robos: " + IntegerToString(NUMBER_ROBOTS_ACTIVE));
      }*/
   }else{
      NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
   }
}

void toNegociate(double spread){
   if( CopyBuffer(handleVol, 0, 0, 2, VOL) == 2){
      if(VOL[0] >= VOL_OPERATION){
          // showComments(orientFI);
          double stop = STOP_LOSS;
          double take = TAKE_PROFIT;
          int total = PositionsTotal() + OrdersTotal();
          
         // double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        
          double minVolume = ACTIVE_VOLUME;
         /* if(total <= 20){
             if(profitSell <= 0 && bestOrientation != DOWN){
                 if( lockBuy == OFF ){
                        executeOrderByRobots(UP, minVolume, stop , take, ORDER, ACTIVE_SUPORT_AND_RESISTANCE );
                 }
             }
             if(profitBuy <= 0 && bestOrientation != UP){
                 if( lockSell == OFF ){
                        executeOrderByRobots(DOWN, minVolume, stop , take, ORDER, ACTIVE_SUPORT_AND_RESISTANCE );
                 }
             }
          }*/ 
          
          
          //ORIENTATION orientFI = verifyForceIndex();
       
          if(total < NUMBER_MAX_ROBOTS){
             if(bestOrientation == MEDIUM){
                  if( lockSell == OFF && qtdBuyersWon <= qtdBuyersLoss){
                        executeOrderByRobots(DOWN, minVolume, stop , take, ORDER, ACTIVE_SUPORT_AND_RESISTANCE );
                  }
                  if( lockBuy == OFF && qtdSellersWon <= qtdSellersLoss){
                        executeOrderByRobots(UP, minVolume, stop , take, ORDER, ACTIVE_SUPORT_AND_RESISTANCE );
                  }
                  if( lockSell == OFF && lockBuy == OFF ){
                     executeOrderByRobots(UP, minVolume, stop , take, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
                     executeOrderByRobots(DOWN, minVolume, stop, take, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
                  }
              } else{            
                  if( lockSell == OFF  && (bestOrientation == DOWN || qtdBuyersWon <= qtdBuyersLoss )){
                     executeOrderByRobots(DOWN, minVolume, STOP_LOSS, TAKE_PROFIT, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
                  }
                  if( lockBuy == OFF && (bestOrientation == UP || qtdSellersWon <= qtdSellersLoss)){
                      executeOrderByRobots(UP, minVolume, STOP_LOSS, TAKE_PROFIT, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
                  }
              }
           }
          /*  */
           
           /* */
        }
     }
}

void detectChangeTendency(){
   double currentPrice = candles[periodAval-1].close;
   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   
   /*TopsAndBottoms tp = getMaxAndMin(NUMBER_TOPS_AND_BOTTOMS, PERIOD_M5);
   
   //
   if(countBuy > NUMBER_ROBOTS &&  qtdBuyersLoss > (countBuy * 0.5) && candles[periodAval-1].high > tp.tops[0] && currentPrice < tp.tops[0]){
     //closeAll();
      protectPositions(30);
       //  executeOrderByRobots(DOWN, minVolume, STOP_LOSS, TAKE_PROFIT, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
   }
   //
   if(countSell > NUMBER_ROBOTS && qtdSellersLoss > (countSell * 0.5) && candles[periodAval-1].low < tp.bottoms[NUMBER_TOPS_AND_BOTTOMS-1]  && currentPrice > tp.bottoms[NUMBER_TOPS_AND_BOTTOMS-1] ){
    // closeAll();
      protectPositions(30);
       //  executeOrderByRobots(UP, minVolume, STOP_LOSS, TAKE_PROFIT, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
   }*/
   
   
    /*
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
   if(profit < 0 && (profit) < -(BALANCE_ACTIVE * ( PERCENT_MARGIN_OPERATION) / 100)){
      closePositionInLoss();
   }else if(profit > 0 && (profit) > (BALANCE_ACTIVE * ( PERCENT_MARGIN_OPERATION) / 100)){
      closePositionInProfit();
   }*/
   
   if((countBuyBackup + countSellBackup) > NUMBER_MAX_ROBOTS * 0.7 && (countBuyBackup + countSellBackup) * 0.5 > (countBuy + countSell)){
    //  WAIT_NEW_CANDLE = 1;
      //countTicks = COUNT_TICKS;
      countBuyBackup = countBuy;
      countSellBackup = countSell;
   }
   
   if(countBuyBackup > 0 && countBuyBackup * 0.5 > countBuy){
      //COUNT_ACTIVE_LOCK = ON;
      //countLockBuy = COUNT_TICKS;
      //lockBuy = ON;
      //NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
   }
   
   if(countSellBackup > 0 && countSellBackup * 0.5 > countSell){
      //COUNT_ACTIVE_LOCK = ON;
      //countLockSell = COUNT_TICKS;
      //lockSell = ON;
      //NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
   }
   
   
   if(ACTIVE_SUPORT_AND_RESISTANCE){
      if(countBuy > NUMBER_ROBOTS && qtdBuyersLoss > (countBuy * 0.5)){
         bestOrientation = MEDIUM;
         if( topsAndBottoms.bottoms[NUMBER_TOPS_AND_BOTTOMS-1] > (currentPrice + 100 * _Point )){
            closeAllPositionsByType(POSITION_TYPE_BUY);
            executeOrderByRobots(DOWN, minVolume, STOP_LOSS, TAKE_PROFIT, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
            bestOrientation = DOWN;
         }
      }
      else if(countSell > NUMBER_ROBOTS && qtdSellersLoss > (countSell * 0.5)){
         bestOrientation = MEDIUM;
         if(topsAndBottoms.tops[0] < (currentPrice - 100 * _Point )){
            closeAllPositionsByType(POSITION_TYPE_SELL);
            executeOrderByRobots(UP, minVolume, STOP_LOSS, TAKE_PROFIT, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
            bestOrientation = UP;
         }
      }
   }

}

void executeOrderByRobots(ORIENTATION orient, double volume, double stop, double take , bool order = false, bool topAndBots = false){
   int total = PositionsTotal() + OrdersTotal();
   bool enableCreate = allowedMarginRobots(volume, stop);
   
   
   if(countRobots < NUMBER_MAX_ROBOTS && enableCreate){
      if(!hasPositionOpen((int)robots[countRobots])){
         if(topAndBots){
            double currentPrice = candles[periodAval-1].close;
            if(orient == UP){
               take = calcPoints(topsAndBottoms.tops[0], currentPrice, false);
               stop = calcPoints(currentPrice, topsAndBottoms.bottoms[NUMBER_TOPS_AND_BOTTOMS-1], false);
            }
            if(orient == DOWN){
               stop = calcPoints(topsAndBottoms.tops[0], currentPrice, false);
               take = calcPoints(currentPrice, topsAndBottoms.bottoms[NUMBER_TOPS_AND_BOTTOMS-1], false);
            }
            if(take < 0 || stop < 0){
               topsAndBottoms = getMaxAndMin(NUMBER_TOPS_AND_BOTTOMS, TIME_FRAME);
            }
         }
         
         if(order != NO_ORDER){
            double limitPrice = (ORDER_LIMIT_POINT * _Point);
            toBuyOrToSellOrders(ORDER, orient, volume, limitPrice, (stop), (take), robots[countRobots]);
         }else{
            toBuyOrToSell(orient, volume, (stop), (take), robots[countRobots]);
         }
      }
   }
   countRobots = total;
}

void moveAllPositions(double spread){
   int pos = PositionsTotal();
   double  average[];
   
   for(int i = pos; i >= 0; i--)  {
      if(hasPositionOpen(i)){
         if(PROTECT_ALL == ON){
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit > 0){
               moveStopPorPrice(i, candles[periodAval-1].close, spread);
            }
         }
         if(ACTIVE_MOVE_STOP == ON){
            activeStopMovelPerPoints(PONTUATION_MOVE_STOP+spread, i);
         }
         if(ACTIVE_MOVE_TAKE == ON){
            moveTakeProfit(i);
         }
         
         if(ACTIVE_MOVE_TO_ZERO_IN_NEW_CANDLE == ON){
            if(moveToZero){
               moveStopToZeroPlusPoint(i, spread);
            }
         }
      }
   }
   
   moveToZero = false;
   if(ORDER != NO_ORDER){
      closeOrdersByDuration(ORDER_DURATION);
   }
   
   decideToCreateOrDeleteRobots();
   if(pos <= 0){
      bestOrientation = MEDIUM;
   }
}


void  decideToCreateOrDeleteRobots(){
   int pos = PositionsTotal() - 1;
   double  average[];
   bool verifyPos = false;
   
   MqlRates actualCandle = candles[periodAval-1];
   MqlRates lastCandle = candles[periodAval-2];
   double pointsInversion = calcPoints(lastCandle.low, lastCandle.close);
   if(countBuy >= NUMBER_MAX_ROBOTS * 0.5){
      verifyPos = true;
   }
   else if(countSell >= NUMBER_MAX_ROBOTS * 0.5){
      verifyPos = true;
   }
   profitBuy = 0;
   profitSell = 0;
   countBuy = 0;
   countSell = 0;
   qtdBuyers = 0;
   qtdBuyersWon = 0;
   qtdBuyersLoss = 0;
   qtdSellers = 0;
   qtdSellersWon = 0;
   qtdSellersLoss = 0;
   double profit2 =  AccountInfoDouble(ACCOUNT_PROFIT);
   for(int position = pos; position >= 0; position--)  {
      if(hasPositionOpen(position)){
         double newTpPrice = 0, newSlPrice = 0;
         ulong ticket = PositionGetTicket(position);
         PositionSelectByTicket(ticket);
         ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
         
         if(verifyMagicNumber(position, magicNumber)){
            long time = PositionGetInteger(POSITION_TIME);
            double tpPrice = PositionGetDouble(POSITION_TP);
            double slPrice = PositionGetDouble(POSITION_SL);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double volume = PositionGetDouble(POSITION_VOLUME);
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT); 
            double pointsProfit =  MathAbs(profit / ACTIVE_VOLUME);
            double pointsTake = calcPoints(entryPrice, tpPrice);
            double pointsSL = calcPoints(entryPrice, slPrice);
            newTpPrice = tpPrice;
            long now = TimeCurrent() ;
            
            double pointsLastCandle = calcPoints(lastCandle.high, lastCandle.low);
            double entryPriceToClose = calcPoints(currentPrice, entryPrice);
            
            if(POINTS_TO_CLOSE > 0){
               if((profit2) > POINTS_TO_CLOSE * ACTIVE_VOLUME ){
                  if(profit < 0){
                     moveStopPorPrice(position, candles[periodAval-1].close, -40);
                  }else{
                     moveStopPorPrice(position, candles[periodAval-1].close, 40);
                  }
                //  WAIT_NEW_CANDLE = 1;
               }
            }
            
            if(type == POSITION_TYPE_BUY ){ 
                  qtdBuyers++; 
                  countBuy++;
                  profitBuy += profit;
                  
                  if(profit > 0 ){
                     qtdBuyersWon++; 
                     if(PROTECT_ORDERS_BY_DURATION > 0 && (time + PROTECT_ORDERS_BY_DURATION) < now){
                          moveStopToZeroPlusPoint(position, 30);
                     }
                  }else if(profit < 0){
                     qtdBuyersLoss++;
                     double points = calcPoints(currentPrice, slPrice);
                     if(MOVIMENT_PERMANENT > 0 && (MathAbs(profit/volume) > pointsSL *0.6)){
                        moveStopOrTake(type, true, position, MOVIMENT_PERMANENT);
                        moveStopOrTake(type, false, position, -(MOVIMENT_PERMANENT));
                        Print("Actived permanent moviment - BUY");
                     }
                     
                     if(CLOSE_IN_MIN_OR_MAX == ON){
                        double pointsLoss = calcPoints(actualCandle.close, entryPrice);
                        if(actualCandle.close <= lastCandle.low){
                           closeBuyOrSell(position);
                           NUMBER_ROBOTS_ACTIVE = (NUMBER_ROBOTS_ACTIVE < NUMBER_ROBOTS ? NUMBER_ROBOTS : NUMBER_ROBOTS_ACTIVE--);
                           Print("Actived permanent moviment - BUY");
                        }
                     }
                  }
             }
             else if(type == POSITION_TYPE_SELL ){
                  qtdSellers++; 
                  countSell++;
                  profitSell += profit;
                  
                  if(profit > 0 ){
                     qtdSellersWon++; 
                     
                     if(PROTECT_ORDERS_BY_DURATION > 0 && (time + PROTECT_ORDERS_BY_DURATION) < now){
                        moveStopToZeroPlusPoint(position, 30);
                     }
                  }else if(profit < 0){
                     qtdSellersLoss++;
                     double points = calcPoints(currentPrice, slPrice);
                     if(MOVIMENT_PERMANENT > 0 && (MathAbs(profit/ volume) > pointsSL *0.6) ){
                        moveStopOrTake(type, true, position, -(MOVIMENT_PERMANENT));
                        moveStopOrTake(type, false, position, MOVIMENT_PERMANENT);
                        Print("Actived permanent moviment - SELL");
                     }
                     
                     if(CLOSE_IN_MIN_OR_MAX == ON){
                        double pointsLoss = calcPoints(actualCandle.close, entryPrice);
                        if(actualCandle.close >= lastCandle.high ){
                           closeBuyOrSell(position);
                           NUMBER_ROBOTS_ACTIVE = (NUMBER_ROBOTS_ACTIVE < NUMBER_ROBOTS ? NUMBER_ROBOTS : NUMBER_ROBOTS_ACTIVE--);
                           Print("Actived close in min or max - SELL");
                        }
                     }
                     
                  }
            }
            
            if(profit < 0 &&  DURATION_POSITION_IN_LOSS > 0 && (time + DURATION_POSITION_IN_LOSS) < now){
               closeBuyOrSell(position);
               NUMBER_ROBOTS_ACTIVE = (NUMBER_ROBOTS_ACTIVE < NUMBER_ROBOTS ? NUMBER_ROBOTS : NUMBER_ROBOTS_ACTIVE--);
               Print("Actived close by duration");
            }
         }
      }
   }
  
  if(pos > 0){
     // double porcSell = (qtdSellersWon > 0 ? countSell / qtdSellersWon : 0) - (qtdSellersLoss > 0 ? countSell / qtdSellersLoss : 0);
      //double porcBuy = (qtdBuyersWon > 0 ? countBuy / qtdBuyersWon : 0) - (qtdBuyersLoss > 0 ? countBuy / qtdBuyersLoss : 0);
      if(profit2 > 0 ){
         if(profitBuy  >= 0  ){
            if( lockBuy == OFF){
               if(bestOrientation != DOWN/*   && orientAv != DOWN && orientRVI == orientMACD */){
                  executeOrderByRobots(UP, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);    
               }     
            }
         }
         else if(profitSell >=  0 ){
            if( lockSell == OFF){
               if(bestOrientation != UP  /* && orientAv != UP && orientRVI == orientMACD*/){
                  executeOrderByRobots(DOWN, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT, ORDER, ACTIVE_SUPORT_AND_RESISTANCE);
               }
           }
         }
      }
      
      if(qtdBuyersWon > qtdSellersWon){
          bestOrientation = UP;
      }else if(qtdBuyersWon < qtdSellersWon){
          bestOrientation = DOWN;
      }else{
          bestOrientation = MEDIUM;
      }
      
    /*  if(profit2 < 0 ){
         double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         if( lockBuy == OFF){
            if(qtdSellersLoss > qtdSellersWon && qtdBuyersWon >= 0 && orientAv != DOWN){
               bestOrientation = UP;
               executeOrderByRobots(UP, minVolume, STOP_LOSS, TAKE_PROFIT, ORDER);
               if(orientMACD == UP && orientRVI == orientMACD){
                  closeAllPositionsByType(POSITION_TYPE_SELL, 1);
               }
            }
         }
         if( lockSell == OFF ){
             if(qtdBuyersLoss > qtdBuyersWon && qtdSellersWon >= 0 && orientAv != UP){
               bestOrientation = DOWN;
               executeOrderByRobots(DOWN, minVolume, STOP_LOSS, TAKE_PROFIT, ORDER);
               if(orientMACD == DOWN && orientRVI == orientMACD){
                 closeAllPositionsByType(POSITION_TYPE_BUY, 1);
               }
            }
         }
      }*/
      countSellBackup = countSell;
      countBuyBackup = countBuy;
   /*   */
   }
}

void  moveTakeProfit( int position = 0){
   double newTpPrice = 0, newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      ulong ticket = PositionGetTicket(position);
      
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
            double tpPrice = PositionGetDouble(POSITION_TP);
            double slPrice = PositionGetDouble(POSITION_SL);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double pointsProfit =  MathAbs(profit / volume);
            double pointsTake = calcPoints(entryPrice, tpPrice);
            double pointsSL = calcPoints(entryPrice, slPrice);
            newTpPrice = tpPrice;
            
            if(profit > 0){
              newSlPrice = slPrice;
              if(pointsProfit >= pointsTake * 0.8 ){
                  double mov =  NormalizeDouble((pointsTake * PERCENT_MOVE / 100 * _Point), _Digits);
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                     newTpPrice = (tpPrice + mov);
                     newSlPrice = (tpPrice + mov);
                   //  slPrice = slPrice > entryPrice ? slPrice : entryPrice;
                  }
                  else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                     newTpPrice = (tpPrice - mov);
                     newSlPrice = (tpPrice - mov);
                    // slPrice = slPrice < entryPrice ? slPrice : entryPrice;
                  }
                  
                  tradeLib.PositionModify(ticket, slPrice, newTpPrice);
                  if(verifyResultTrade()){
                     Print("Take movido");
                  }
              }
           }
       }
   }
}



void  moveStopPorPrice(int position, double currentPrice = 0, double points = 0){
   int pos = PositionsTotal();
   if(hasPositionOpen(position)){ 
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double tpPrice = PositionGetDouble(POSITION_TP);
        
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            tradeLib.PositionModify(ticket, currentPrice+(points*_Point), tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido pro zero");
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            tradeLib.PositionModify(ticket, currentPrice-(points*_Point), tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido pro zero");
            }
         }
      }
   }
}

bool allowedMarginRobots(double volumePos, double pointStopPos){
   if(CALCULATE_MARGIN == ON){
      int pos = PositionsTotal();
      double riskTotal = (pointStopPos * volumePos);
      
      for(int position = pos; position >= 0; position--)  {
         if(hasPositionOpen(position)){
            ulong ticket = PositionGetTicket(position);
            PositionSelectByTicket(ticket);
            ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
            if(verifyMagicNumber(position, magicNumber)){
               double slPrice = PositionGetDouble(POSITION_SL);
               double volume = PositionGetDouble(POSITION_VOLUME);
               double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               double pointsSL = calcPoints(entryPrice, slPrice);
               riskTotal += (pointsSL * volume); 
            }
         }
      }
      
   
      //double profit = AccountInfoDouble(ACCOUNT_PROFIT);
      BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
      if(riskTotal <= (BALANCE_ACTIVE * PERCENT_MARGIN_OPERATION / 100)){
         return true;
      }else{
         return false;
      }
   }else{
      return true;
   }
}

void  moveStopToZeroPlusPoint(int position = 0, double points = 0, bool protectPriceActual = false){
   double newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double tpPrice = PositionGetDouble(POSITION_TP);
         double slPrice = PositionGetDouble(POSITION_SL);
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double profit = PositionGetDouble(POSITION_PROFIT);
        
         if(profit > 0){
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
               if(!protectPriceActual){
                  if(slPrice < entryPrice){
                     if(currentPrice > entryPrice+(points*_Point)){
                        tradeLib.PositionModify(ticket, entryPrice+(points*_Point), tpPrice);
                     }
                     else{
                        tradeLib.PositionModify(ticket, entryPrice, tpPrice);
                     }
                  }
               }else{
                   tradeLib.PositionModify(ticket, currentPrice-(points*_Point), tpPrice); 
               }  
               
               if(verifyResultTrade()){
                  Print("Stop movido pro zero");
               }
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
               if(!protectPriceActual){
                  if(slPrice > entryPrice){
                     if(currentPrice < entryPrice-(points*_Point)){
                        tradeLib.PositionModify(ticket, entryPrice-(points*_Point), tpPrice);
                     }
                     else{
                        tradeLib.PositionModify(ticket, entryPrice, tpPrice);
                     }
                  }
               }else{
                   tradeLib.PositionModify(ticket, currentPrice+(points*_Point), tpPrice);
               }  
               
               if(verifyResultTrade()){
                  Print("Stop movido pro zero");
               }
            }
         }
      }
   }
}

void  activeStopMovelPerPoints(double points, int position = 0){
   double newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      Print("Mover Stop");
      PositionSelectByTicket(PositionGetTicket(position));
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double profit = PositionGetDouble(POSITION_PROFIT);
         if( profit > 0){
            double tpPrice = PositionGetDouble(POSITION_TP);
            double slPrice = PositionGetDouble(POSITION_SL);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double entryPoints = 0, pointsInversion =  MathAbs(profit / ACTIVE_VOLUME);
            double pointsTake = calcPoints(entryPrice, tpPrice);
            bool modify = false, inversion = false;
            ORIENTATION orient = MEDIUM;
            newSlPrice = slPrice;
            
            double pointsMove = (points * _Point);
            double percentMove = (points * PERCENT_MOVE / 100 * _Point);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
               //tpPrice = NormalizeDouble((tpPrice + (points * _Point)), _Digits);
               if(currentPrice >= (slPrice + pointsMove) && slPrice >= entryPrice){
                  newSlPrice = NormalizeDouble((slPrice + percentMove), _Digits);
                  modify = true;
               }
               else if(currentPrice >= (entryPrice + pointsMove) && slPrice <= entryPrice){
                  newSlPrice = NormalizeDouble((entryPrice ), _Digits);
                  modify = true;
               }
              // else if(currentPrice > entryPrice + (10 * _Point)){
                //   newSlPrice = NormalizeDouble((entryPrice + (10 * _Point) ), _Digits);
                  // modify = true;
               //}
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
             //  tpPrice = NormalizeDouble((tpPrice - (points * _Point)), _Digits);
               if(currentPrice <= (slPrice - pointsMove) && slPrice <= entryPrice ){
                  newSlPrice = NormalizeDouble((slPrice - percentMove), _Digits);
                  modify = true;
               }else if(currentPrice <= (entryPrice - pointsMove) && slPrice >= entryPrice ){
                  newSlPrice = NormalizeDouble((entryPrice), _Digits);
                  modify = true;
               }
              // else if(currentPrice < entryPrice - (10 * _Point)){
                //   newSlPrice = NormalizeDouble((entryPrice - (10 * _Point)), _Digits);
                 //  modify = true;
               //}
            }
               
            if(modify == true ){
               tradeLib.PositionModify(PositionGetTicket(position), newSlPrice, tpPrice);
               if(verifyResultTrade()){
                  Print("Stop movido");
               }
            }
         } 
       }
   }
}


void  closePositionByDuration(long duration){
   int pos = OrdersTotal() - 1;
   for(int position = pos; position >= 0; position--)  {
      ulong ticket = PositionGetTicket(position);
      if(hasPositionOpen(position)){
         MqlDateTime structActual, structTime;
         long time = PositionGetInteger(POSITION_TIME);
         TimeToStruct((time+ duration), structActual);
         TimeToStruct((time), structTime);
         datetime durationTotal = StructToTime(structActual);
         datetime timeInit = StructToTime(structTime);
         datetime now = TimeCurrent();
         
         if(now > durationTotal){
            closeBuyOrSell(position);
            if(verifyResultTrade()){
               Print("Close Position");
            }
         }
      }
   }
}



void  closeOrdersByDuration(long duration){
   int pos = OrdersTotal() - 1;
   for(int position = pos; position >= 0; position--)  {
      if(hasOrderOpen(position)){
         ulong ticket = OrderGetTicket(position);
         ulong magicNumber = OrderGetInteger(ORDER_MAGIC);
         if(verifyMagicNumber(position, magicNumber, true)){
            MqlDateTime structActual, structTime;
            long time = OrderGetInteger(ORDER_TIME_SETUP);
            TimeToStruct((time+ duration), structActual);
            TimeToStruct((time), structTime);
            datetime durationTotal = StructToTime(structActual);
            datetime timeInit = StructToTime(structTime);
            datetime now = TimeCurrent();
            
            if(now > durationTotal){
               tradeLib.OrderDelete(ticket);
               if(verifyResultTrade()){
                  Print("Close Order");
               }
            }
         }
      }
   }
}

void moveStopPerPoint(ENUM_POSITION_TYPE type, double points){
   int pos = PositionsTotal() - 1;
   for(int position = pos; position >= 0; position--)  {
      moveStopOrTake(type, true, position, points);
   }
}  

void moveTakePerPoint(ENUM_POSITION_TYPE type, double points){
   int pos = PositionsTotal() - 1;
   for(int position = pos; position >= 0; position--)  {
      moveStopOrTake(type, false, position, points);
   }
}  

void moveStopOrTake(ENUM_POSITION_TYPE type, bool stop, int position, double points){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double slPrice = PositionGetDouble(POSITION_SL);
         double tpPrice = PositionGetDouble(POSITION_TP);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double pointsSl   = calcPoints(currentPrice, slPrice);
         double newTP = NormalizeDouble(tpPrice + (points * _Point), _Digits);
         double newSl = NormalizeDouble(slPrice + (points * _Point), _Digits);
         
            
     
      
         if(PositionGetInteger(POSITION_TYPE) == type){
            double valN = NormalizeDouble(entryPrice - (points * _Point), _Digits);
            double valP =NormalizeDouble( entryPrice + (points * _Point), _Digits);
            if(stop ){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                  if(newSl < valN){
                     tradeLib.PositionModify(ticket, newSl,tpPrice);   
                  }
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  if(newSl > valP){
                     tradeLib.PositionModify(ticket, newSl,tpPrice);   
                  }
               }      
            }else{
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                  if(newTP < valN){
                     tradeLib.PositionModify(ticket, slPrice,newTP);
                  }
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  if(newTP > valP){
                   tradeLib.PositionModify(ticket, slPrice,newTP);
                  }
               }
            }
            if(verifyResultTrade()){
               Print("Take movido");
            }
         }
       }
    }
   
}

BordersOperation normalizeTakeProfitAndStopLoss(double stopLoss, double takeProfit){
   BordersOperation borders;
   // modificação para o indice dolar DOLAR_INDEX
   if(stopLoss != 0 || takeProfit != 0){
      if( _Symbol == "USDHKD" ){
         borders.min = (stopLoss / 1000);
         borders.max = (takeProfit / 1000);  
      }if(_Digits == 3  ){
         borders.min = (stopLoss * 1000);
         borders.max = (takeProfit * 1000);  
      }else{
         borders.min = NormalizeDouble((stopLoss * _Point), _Digits);
         borders.max = NormalizeDouble((takeProfit * _Point), _Digits); 
      }
   }
   
   return borders;
}


void toBuyOrder(TYPE_ORDER orderType, double volume, double limitPrice, double stopLoss, double takeProfit, datetime duration){
   double stopLossNormalized = NormalizeDouble((limitPrice - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((limitPrice + takeProfit), _Digits);
   
   if(orderType == LIMIT){
      tradeLib.BuyLimit(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
   }  
   else if(orderType == STOP){
      tradeLib.BuyStop(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
   } 
   
   if(verifyResultTrade()){
      Print("Compra Limitada realizada.");
   }
}

void toSellOrder(TYPE_ORDER orderType, double volume, double limitPrice, double stopLoss, double takeProfit, datetime duration){
   double stopLossNormalized = NormalizeDouble((limitPrice + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((limitPrice - takeProfit), _Digits);
   
   if(orderType == LIMIT){
      tradeLib.SellLimit(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
   }  
   else if(orderType == STOP){
      tradeLib.SellStop(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
   } 
   
   if(verifyResultTrade()){
      Print("Venda Limitada realizada.");
   }
}

void toBuy(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
   tradeLib.Buy(volume, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized); 
  
   if(verifyResultTrade()){
      Print("Compra realizada.");
   }
}

void toSell(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
   tradeLib.Sell(volume, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);   
   
   if(verifyResultTrade()){
      Print("Venda realizada.");
   }
}

bool realizeDealsOrders(TYPE_ORDER orderType, TYPE_NEGOCIATION typeDeals, double volume, double limitPrice, double stopLoss, double takeProfit, ulong magicNumber, datetime duration){
   if(typeDeals != NONE){
   
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
    //  if(hasPositionOpen() == false) {
         if(typeDeals == BUY){ 
            toBuyOrder(orderType, volume,limitPrice, borders.min, borders.max, duration);
         }
         else if(typeDeals == SELL){
            toSellOrder(orderType, volume,limitPrice, borders.min, borders.max, duration);
         }
         
         if(verifyResultTrade()){
            tradeLib.SetExpertMagicNumber(magicNumber);
            Print("MAGIC NUMBER: " + IntegerToString(magicNumber));
            return true;
         }
      // }
    }
    
    return false;
 }
 
bool realizeDeals(TYPE_NEGOCIATION typeDeals, double volume, double stopLoss, double takeProfit, ulong magicNumber){
   if(typeDeals != NONE){
   
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
    //  if(hasPositionOpen() == false) {
         if(typeDeals == BUY){ 
            toBuy(volume, borders.min, borders.max);
         }
         else if(typeDeals == SELL){
            toSell(volume, borders.min, borders.max);
         }
         
         if(verifyResultTrade()){
            tradeLib.SetExpertMagicNumber(magicNumber);
            Print("MAGIC NUMBER: " + IntegerToString(magicNumber));
            return true;
         }
      // }
    }
    
    return false;
 }

void closeBuyOrSell(int position){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         tradeLib.PositionClose(ticket);
         if(verifyResultTrade()){
            Print("Negociação concluída.");
            countRobots = (countRobots-1 < 0 ? 0 : countRobots--);
         }
      }
   }
}

bool verifyMagicNumber(int position = 0, ulong magicNumberRobot = 0, bool order = false){
   if(USE_MAGIC_NUMBER == OFF || IGNORE_MAGIC == ON){
      return true;
   }
   
   if(!order){
      if(hasPositionOpen(position)){
         if(magicNumberRobot == MAGIC_NUMBER){
            return true;
         }
      }
   }else{
      if(hasOrderOpen(position)){ 
         if(magicNumberRobot == MAGIC_NUMBER){
            return true;
         }
      }
   }
   
   return false;
   
}

bool toBuyOrToSellOrders(TYPE_ORDER orderType, ORIENTATION orient, double volume, double limitPrice, double stopLoss, double takeProfit, ulong magicNumber, datetime duration = 0){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   double actualPrice = candles[periodAval-1].close;
   if(orient == UP){
      if(orderType == LIMIT){
         limitPrice = actualPrice - limitPrice;
      }
      else if(orderType == STOP){
         limitPrice = actualPrice + limitPrice;
      }
   }else if(orient == DOWN){
      if(orderType == LIMIT){
         limitPrice = actualPrice + limitPrice;
      }
      else if(orderType == STOP){
         limitPrice = actualPrice - limitPrice;
      }
   }
   
   return realizeDealsOrders(orderType, typeDeal, volume, limitPrice, stopLoss, takeProfit, magicNumber, duration);
   //getHistory();
}

bool toBuyOrToSell(ORIENTATION orient, double volume, double stopLoss, double takeProfit, ulong magicNumber){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDeals(typeDeal, volume, stopLoss, takeProfit, magicNumber);
   //getHistory();
}

string verifyPower(POWER power){
   if(power == ON){
      return "ON";
   }else{
      return "OFF";
   }
}

void closePositionInLoss(){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(i, magicNumber)){
          double profit = PositionGetDouble(POSITION_PROFIT);
          if(profit < 0){
            closeBuyOrSell(i);
          }
      } 
   }
}


void closePositionInProfit(){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(i, magicNumber) ){
          double profit = PositionGetDouble(POSITION_PROFIT);
          if(profit > 0){
            closeBuyOrSell(i);
          }
      } 
   }
}

bool hasOrderOpen(uint position ){ 
   ulong ticket = OrderGetTicket(position);
   if(OrderSelect(ticket) == true) {
      return true;       
   }
    
   return false;
}

bool hasPositionOpen(int position ){
   // string symbol = PositionGetSymbol(position);
 //   PositionSelect(symbol) == true && _Symbol == symbol
      ulong ticket = PositionGetTicket(position);
    if(PositionSelectByTicket(ticket) == true ) {
      return true;       
    }
    
    return false;
}

bool verifyResultTrade(){
   if(tradeLib.ResultRetcode() == TRADE_RETCODE_PLACED || tradeLib.ResultRetcode() == TRADE_RETCODE_DONE){
      printf("Ordem de %s executada com sucesso.");
      return true;
   }else{
      Print("Erro de execução de ordem ", GetLastError());
      ResetLastError();
      return false;
   }
}

BordersOperation drawBorders(double precoAtual, double pontuationEstimateHigh = 0, double pontuationEstimateLow = 0){
   BordersOperation borders;
   /*
   int numCandles = 2;
   int copiedPrice = CopyRates(_Symbol,TIME_FRAME,0,numCandles,candles);
   if(copiedPrice == numCandles){
      for(int i = 0; i < numCandles; i++){
         pontuationEstimateHigh += (candles[i].high) ;
         pontuationEstimateLow += (candles[i].low);
      }
      pontuationEstimateHigh = pontuationEstimateHigh /numCandles;
      pontuationEstimateLow = pontuationEstimateLow /numCandles;
      borders.max = MathAbs(_Point * pontuationEstimateHigh + precoAtual);
      borders.min = MathAbs(_Point * pontuationEstimateLow - precoAtual);
   }*/
   
   borders.max = MathAbs(_Point * pontuationEstimateHigh + precoAtual);
   borders.min = MathAbs(_Point * pontuationEstimateLow - precoAtual);
  
   drawHorizontalLine(borders.max, 0, "BorderMax", clrYellow);
   drawHorizontalLine(borders.min, 0, "BorderMin", clrYellow);
   //Print("Atualização de Bordas");
   
   return borders;
}

bool hasNewCandle(){
   static datetime lastTime = 0;
   
   datetime lastBarTime = (datetime)SeriesInfoInteger(Symbol(),PERIOD_CURRENT,SERIES_LASTBAR_DATE);
   
   //primeira chamada da funcao
   if(lastTime == 0){
      lastTime = lastBarTime;
      return false;
   }
   
   if(lastTime != lastBarTime){
      lastTime = lastBarTime;
      return true;
   }
   
   return false;
}

string verifyPeriod(ORIENTATION orient){
   if(orient == DOWN){
      return "DOWN";
   }
   if(orient == UP){
      return "UP";
   }
   
   return "MEDIUM";
}

ORIENTATION verifySTHO(){
   if( CopyBuffer(handleStho,0,0,periodAval,STHO1) == periodAval && CopyBuffer(handleStho,1,0,periodAval,STHO2) == periodAval){
      double stho11 = STHO1[periodAval-3];
      double stho12 = STHO1[periodAval-2]; 
      double stho13 = STHO1[periodAval-1];
      
      double stho21 = STHO2[periodAval-3];
      double stho22 = STHO2[periodAval-2]; 
      double stho23 = STHO2[periodAval-1];
      
     /* if((MathAbs(stho11) >= 80 &&  MathAbs(stho12) >= 80 && MathAbs(stho13) >= 80) && 
         (MathAbs(stho21) >= 80 &&  MathAbs(stho22) >= 80 &&   MathAbs(stho23) >= 80 )){
          return DOWN;
      }else if((MathAbs(stho11) <= 20 &&  MathAbs(stho12) <= 20 && MathAbs(stho13) <= 20) && 
         (MathAbs(stho21) <= 20 &&  MathAbs(stho22) <= 20 &&   MathAbs(stho23) <= 20 )){
          return UP;
      }*/
      
      if(MathAbs(stho13) >= 80 && MathAbs(stho23) >= 80){
          return DOWN;
      }else if(MathAbs(stho13) <= 20 &&  MathAbs(stho23) <= 20){
          return UP;
      }
   }

   return MEDIUM;
}


ORIENTATION verifyRVI(){
    if(CopyBuffer(handleIRVI,0,0,periodAval,RVI1) == periodAval &&    
      CopyBuffer(handleIRVI,1,0,periodAval,RVI2) == periodAval){
      double rvi1 = RVI1[periodAval-1];
      double rvi2 = RVI2[periodAval-1];
      if(rvi1 < rvi2 && rvi2 < 0){
         //Print("Trend DOWN");
         return DOWN;
      }
      if(rvi1 > rvi2 && rvi1 > 0){
         //Print("Trend UP");
         return UP;
      }
      
      if(rvi1 < rvi2 && rvi1 > 0){
         //Print("CORRECTION DOWN");
         return DOWN;
      }
      if(rvi1 > rvi2 && rvi2 < 0){
         //Print("CORRECTION UP");
         return UP;
      }
   }

   return MEDIUM;
}

ORIENTATION verifyCCI(){
  if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval){
       double valCCI1 = CCI[periodAval-3];
       double valCCI2 = CCI[periodAval-2];
       double valCCI3 = CCI[periodAval-1];
      if( valCCI3 >= 100){
         return DOWN;
      }
      if( valCCI3 <= -100){
         return UP;
      }
   } /**/

   return MEDIUM;
}
ORIENTATION verifyForceIndex(){
   double forceIArray[], forceValue[5], fiMax = 0, fiMin = 0, fMedia = 0;
   //ArraySetAsSeries(forceIArray, true);   
   
   if(CopyBuffer(handleFI,0,0,1,forceIArray) == 1){
      if(handleFI > 0){
        /* forceValue[0] = NormalizeDouble(forceIArray[handleFI-1], _Digits);
         forceValue[1] = NormalizeDouble(forceIArray[handleFI-2], _Digits);
         forceValue[2] = NormalizeDouble(forceIArray[handleFI-3], _Digits);
         forceValue[3] = NormalizeDouble(forceIArray[handleFI-4], _Digits);
         forceValue[4] = NormalizeDouble(forceIArray[handleFI-5], _Digits);
         fMedia =  (forceValue[0] + forceValue[1] + forceValue[2] + forceValue[3] + forceValue[4]) / 5;
         */
         fMedia = forceIArray[0];
         if(fMedia > 1500 ){
            return UP;
         }else if(fMedia < -1500  ){
            return DOWN;
         }
      }
   }
   
   return MEDIUM;
}

ORIENTATION verifyOrientationMACD(){
   if(CopyBuffer(handleMACD, 0, 0, periodAval, MACD) == periodAval){
      double macd0 = MACD[periodAval-3];
      double macd1 = MACD[periodAval-2];
      double macd2 = MACD[periodAval-1];
      
      if(MathAbs(macd0) >= MathAbs(macd1) && MathAbs(macd1) >= MathAbs(macd2)){
         if(macd2 < 0){
            return UP;
         }
         else if(macd2 > 0){
            return DOWN;
         }
      }else if(MathAbs(macd0) <= MathAbs(macd1) && MathAbs(macd1) <= MathAbs(macd2)){
         if( macd2 < 0){
            return DOWN;
         }
         else if(macd2 > 0){
            return UP;
         }
      }else if(MathAbs(macd0) <= MathAbs(macd1) && MathAbs(macd1) >= MathAbs(macd2)){
         if( macd2 < 0){
            return UP;
         }
         else if(macd2 > 0){
            return DOWN;
         }
      }else if(MathAbs(macd0) >= MathAbs(macd1) && MathAbs(macd1) <= MathAbs(macd2)){
         if( macd2 < 0){
            return DOWN;
         }
         else if(macd2 > 0){
            return UP;
         }
      }
   }

   return MEDIUM;
}


bool verifyIfShadowBiggerThanBody(MqlRates& candle, double points = 0){
   double pointsTotal = calcPoints(candle.low, candle.high);
   if(pointsTotal >= points){
      double pointsShadowLow = 0;
      double pointsShadowHigh = 0;
      double total = pointsTotal * 0.6;
      if(verifyIfOpenBiggerThanClose(candle)){
         pointsShadowHigh = calcPoints(candle.open, candle.high);
         pointsShadowLow = calcPoints(candle.close, candle.low);
      }else if(!verifyIfOpenBiggerThanClose(candle)){
         pointsShadowLow = calcPoints(candle.open, candle.low);
         pointsShadowHigh = calcPoints(candle.close, candle.high);
      }
   
      double pointsCandle = pointsTotal - (pointsShadowLow + pointsShadowHigh);
      return pointsShadowHigh > pointsCandle + pointsShadowLow || pointsShadowLow > pointsCandle + pointsShadowHigh ;
   }
   
   return false;
}

ORIENTATION verifyValidCandle(MqlRates& candle, double points = 0){
   double pointsCandle = calcPoints(candle.close, candle.open);
   double pointsShadow = calcPoints(candle.low, candle.high);
   
   if(points == 0 || pointsCandle >= points){
      if(MathAbs(pointsCandle-pointsShadow) < pointsCandle){
         if(verifyIfOpenBiggerThanClose(candle)){
            return DOWN;
         }else if(!verifyIfOpenBiggerThanClose(candle)){
            return UP;
         }
      }
   }

   return MEDIUM;
}

ORIENTATION verifyOrientationAverage(double closePrice){
   if(CopyBuffer(handleaverages[0], 0, 0, periodAval, averages8) == periodAval && 
      CopyBuffer(handleaverages[1], 0, 0, periodAval, averages20) == periodAval &&
      CopyBuffer(handleaverages[2], 0, 0, periodAval, averages80) == periodAval &&  
      CopyBuffer(handleaverages[3], 0, 0, periodAval, averages200) == periodAval){
         if(averages20[periodAval-1] < closePrice && averages80[periodAval-1] < closePrice && averages8[periodAval-1] < closePrice){
            return UP;
         }
         
         if(averages20[periodAval-1] > closePrice&& averages80[periodAval-1] > closePrice && averages8[periodAval-1] > closePrice){
            return DOWN;
         }
      }
   
   return MEDIUM;
}

void protectPositions(double points = 0, bool protectPriceActual = false){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      moveStopToZeroPlusPoint(i, points, protectPriceActual);
   }
}


void closePositionByType(ENUM_POSITION_TYPE type, int i){
   if(hasPositionOpen(i)){
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(i, magicNumber) && PositionGetInteger(POSITION_TYPE) == type){
            closeBuyOrSell(i);
      }
   }
}


void closeAllPositionsByType(ENUM_POSITION_TYPE type, int qtd = 0){
   int pos = PositionsTotal()-1;
   
   if(qtd > 0){
      pos = qtd;   
   }
   
   for(int i = pos; i >= 0; i--)  {
      closePositionByType(type, i);
   }
}

void drawHorizontalLine(double price, datetime time, string nameLine, color indColor){
   ObjectCreate(ChartID(),nameLine,OBJ_HLINE,0,time,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(ChartID(),nameLine,0,time,price);
}

void drawArrow(datetime time, string nameLine, double price, ORIENTATION orientation, color indColor){
   if(orientation == UP){
      ObjectCreate(ChartID(),nameLine,OBJ_ARROW_UP,0,time,price);
      ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   }else{
      ObjectCreate(ChartID(),nameLine,OBJ_ARROW_DOWN,0,time,price);
      ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   }
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   ObjectCreate(ChartID(),nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, string fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
   ObjectCreate(ChartID(),nameLine,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,nameLine,OBJPROP_XDISTANCE,xx);
   ObjectSetInteger(0,nameLine,OBJPROP_YDISTANCE, yy);
   ObjectSetInteger(0,nameLine,OBJPROP_XSIZE, largura);
   ObjectSetInteger(0,nameLine,OBJPROP_YSIZE, altura);
   ObjectSetInteger(0,nameLine,OBJPROP_CORNER, canto);
   ObjectSetInteger(0,nameLine,OBJPROP_FONTSIZE, tamanho);
   ObjectSetString(0,nameLine,OBJPROP_FONT, fonte);
   ObjectSetString(0,nameLine,OBJPROP_TEXT, text);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR, corTexto);
   ObjectSetInteger(0,nameLine,OBJPROP_BGCOLOR, corFundo);
   ObjectSetInteger(0,nameLine,OBJPROP_BORDER_COLOR, corBorda);
}


bool timeToProtection(string startTime, string endTime){
   datetime now = TimeCurrent();
   datetime start = StringToTime(startTime);
   datetime end = StringToTime(endTime);
   
   if(startTime == "00:00" && endTime == "00:00"){
      return false;
   }else{
      if(now > start && now < end){
         return true;
      }
   }
   
   return false;
}

bool verifyIfOpenBiggerThanClose(MqlRates& candle){
   return candle.open > candle.close;
}

ORIENTATION getOrientationPerCandles(MqlRates& prev, MqlRates& actual){
   if(actual.open > prev.open){
      return UP;
   }else if(actual.open < prev.open){
      return DOWN;
   }
   
   return MEDIUM;
}


MainCandles generateMainCandles(){
   MainCandles mainCandles;
   int copiedPrice = CopyRates(_Symbol,TIME_FRAME,0,3,candles);
   if(copiedPrice == 3){
      mainCandles.actual = candles[2];
      mainCandles.last = candles[1];
      mainCandles.secondLast = candles[0];
      mainCandles.instantiated = true;
   }else{
      mainCandles.instantiated = false;
   }
   
   return mainCandles;
}

bool isNewDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   
   if((structActual.day_of_year - structDate.day_of_year) > 0){
      return true;
   }else{
      return false;
   }
}

void closeAll(){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      if(hasPositionOpen(i)){
         ulong ticket = PositionGetTicket(i);
         PositionSelectByTicket(ticket);
         ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
         if(verifyMagicNumber(i, magicNumber)){
            closeBuyOrSell(i);
         }
      }
   }
}

int daysDiff(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   return (structActual.day_of_year - structDate.day_of_year);
}

int getActualDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   return (structActual.day_of_year - structDate.day_of_year);
}

double calcPoints(double val1, double val2, bool absValue = true){
   if(absValue){
      return MathAbs(val1 - val2) / _Point;
   }else{
      return (val1 - val2) / _Point;
   }
}

color pressButtonColor(bool var, color primary = clrBlue, color secundary =  clrBlueViolet){
   return (var == true ? primary : secundary);
}

TopsAndBottoms getMaxAndMin(int qtdItems, ENUM_TIMEFRAMES timeFrame){
      TopsAndBottoms tpb;
      ArrayResize(tpb.bottoms, NUMBER_TOPS_AND_BOTTOMS);
      ArrayResize(tpb.tops, NUMBER_TOPS_AND_BOTTOMS);
      
      double high[], low[];
      double actualPrice = candles[periodAval-1].close;
      int max = 0, min = 0, minTops = 0, maxBottoms = 0;
      int backupQtdItems = 0, maxBackupQtdItems = 20;
      int qtdCandles = 0;
      
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      for(int i = 0; i < NUMBER_TOPS_AND_BOTTOMS; i++){
         if(CopyHigh(_Symbol, timeFrame, backupQtdItems, qtdItems, high) >= qtdItems && CopyLow(_Symbol, TIME_FRAME, backupQtdItems, qtdItems, low) >= qtdItems){
            max = ArrayMaximum(high, 0, qtdItems);
            min = ArrayMinimum(low, 0, qtdItems);
            backupQtdItems =  qtdItems + backupQtdItems;
            
            tpb.tops[i] = NormalizeDouble(high[max], _Digits);
            tpb.bottoms[i] = NormalizeDouble(low[min], _Digits);
         } 
      }
      
      /*
      minTops = ArrayMinimum(tpb.tops, 0, NUMBER_TOPS_AND_BOTTOMS);
      while(tpb.tops[minTops] <=  actualPrice){
         tpb.tops[minTops] = high[max] + (maxBackupQtdItems * _Point);
         minTops = ArrayMinimum(tpb.tops, 0, NUMBER_TOPS_AND_BOTTOMS);
         maxBackupQtdItems += maxBackupQtdItems;
      }
      
      maxBottoms = ArrayMaximum(tpb.bottoms, 0, NUMBER_TOPS_AND_BOTTOMS);
      while(tpb.bottoms[maxBottoms] >=  actualPrice){
         tpb.bottoms[maxBottoms] = low[min] - (maxBackupQtdItems * _Point);
         maxBottoms = ArrayMaximum(tpb.bottoms, 0, NUMBER_TOPS_AND_BOTTOMS);
         maxBackupQtdItems += maxBackupQtdItems;
      }*/
    
     
      qtdCandles = 0;
      minTops = ArrayMinimum(tpb.tops, 0, NUMBER_TOPS_AND_BOTTOMS);
      while(tpb.tops[minTops] <=  actualPrice){
         if(CopyHigh(_Symbol, timeFrame, qtdCandles, maxBackupQtdItems, high) >= NUMBER_TOPS_AND_BOTTOMS ){
            max = ArrayMaximum(high, 0, maxBackupQtdItems);
            qtdCandles += maxBackupQtdItems;
            
            tpb.tops[minTops] = high[max];
            minTops = ArrayMinimum(tpb.tops, 0, NUMBER_TOPS_AND_BOTTOMS);
         }
      }
    
      
      qtdCandles = 0;
      maxBottoms = ArrayMaximum(tpb.bottoms, 0, NUMBER_TOPS_AND_BOTTOMS);
      while(tpb.bottoms[maxBottoms] >= actualPrice ){
         if(CopyLow(_Symbol, timeFrame, qtdCandles, maxBackupQtdItems, low) >= NUMBER_TOPS_AND_BOTTOMS ){
            min = ArrayMinimum(low, 0, maxBackupQtdItems);
            qtdCandles += maxBackupQtdItems;
            
            tpb.bottoms[maxBottoms] = low[min];
            maxBottoms = ArrayMaximum(tpb.bottoms, 0, NUMBER_TOPS_AND_BOTTOMS);
         }
      }/**/
      
      ArraySort(tpb.tops);
      ArraySort(tpb.bottoms);
      datetime now = TimeCurrent();
      for(int i = 0; i < NUMBER_TOPS_AND_BOTTOMS; i++){
         drawHorizontalLine(tpb.tops[i], now, "topo-" + IntegerToString(i), clrYellow);
         drawHorizontalLine(tpb.bottoms[i], now, "fundo-" + IntegerToString(i), clrWhite);
      }
      
      return tpb;
}

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}

void generateButtons(){

      createButton("btnCloseBuy", 20, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Compras", clrWhite, clrRed, clrRed, false);
      createButton("btnCloseSell", 230, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Vendas", clrWhite, clrRed, clrRed, false);
      createButton("btnCloseAll", 440, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
      
      createButton("btnCloseProfit", 20, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar com lucro.", clrWhite, clrRed, clrRed, false);
      createButton("btnBuy", 230, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Criar " + IntegerToString(NUMBER_ROBOTS) +" Robôs de Compra", clrWhite, clrBlue, clrBlue, false);
      createButton("btnSell", 440, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Criar " + IntegerToString(NUMBER_ROBOTS) +" Robôs de Venda", clrWhite, clrBlue, clrBlue, false);
     
      createButton("btnDoubleVol", 20, 250, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Multiplicar Volume por 2", clrWhite, clrBlue, clrBlue, false);
      createButton("btnDivVol", 230, 250, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Dividir Volume por 2", clrWhite, clrBlue, clrBlue, false);
      createButton("btnResetVol", 440, 250, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Resetar Volume", clrWhite, clrBlue, clrBlue, false);
    
      createButton("btnLockBuy", 20, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Travar Comprar", clrWhite, pressButtonColor(lockBuy == OFF), pressButtonColor(lockBuy == OFF), false);
      createButton("btnLockSell", 230, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Travar Venda", clrWhite, pressButtonColor(lockSell == OFF), pressButtonColor(lockSell == OFF), false);
      createButton("btnLockRobots", 440, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Travar robôs", clrWhite, pressButtonColor(!LOCK_ROBOTS),  pressButtonColor(!LOCK_ROBOTS), false);
        
      createButton("btnMoveStop", 20, 200, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Proteger Negociações", clrWhite, clrGreen, clrGreen, false);
       createButton("moveToPrice", 230, 200, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Mover Stop Pro Preço", clrWhite, clrGreen, clrGreen, false);
     
     
     /* createButton("btnUpTakeBuy", 230, 200, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "+100 Pts Take na Compra", clrWhite, clrGreen, clrGreen, false);
      createButton("btnDownTakeBuy", 440, 200, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "-100 Pts Take na Compra", clrWhite, clrGreen, clrGreen, false);
      
      createButton("btnUpStopBuy", 20, 150, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "+100 Pts Stop na Compra", clrWhite, clrGreen, clrGreen, false);
      createButton("btnDownStopBuy", 230, 150, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "-100 Pts Stop na Compra", clrWhite, clrGreen, clrGreen, false);
      createButton("btnUpTakeSell", 440, 150, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "+100 Pts Take na Venda", clrWhite, clrGreen, clrGreen, false);
      
      createButton("btnDownTakeSell", 20, 100, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "-100 Pts Take na Venda", clrWhite, clrGreen, clrGreen, false);
      createButton("btnUpStopSell", 230, 100, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "+100 Pts Stop na Venda", clrWhite, clrGreen, clrGreen, false);
      createButton("btnDownStopSell", 440, 100, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "-100 Pts Stop na Venda", clrWhite, clrGreen, clrGreen, false);
      */
     
}
