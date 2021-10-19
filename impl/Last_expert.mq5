#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>


CPositionInfo  tradePosition;                   // trade position object
CTrade tradeLib;

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

input bool ORDER = true;
input int ORDER_DURATION = 300;
input double ORDER_LIMIT_POINT = 150;
input long DURATION_POSITION_IN_LOSS = 0;
input double  POINTS_TO_CLOSE = 50000;
input POWER  EXPONENTIAL_ROBOTS = ON;
input POWER  EXPONENTIAL_VOLUME = ON;
input POWER  ACTIVE_MOVE_TAKE = ON;
input POWER  ACTIVE_MOVE_STOP = ON;
input double PERCENT_MOVE = 70;
input double PONTUATION_MOVE_STOP = 400;
input string CLOSING_TIME = "23:00";
input ulong MAGIC_NUMBER = 3232131231231231;
input int NUMBER_ROBOTS = 10;
input int NUMBER_MAX_ROBOTS = 400;
input int COUNT_TICKS = 60;
input double TAKE_PROFIT = 300;
input double STOP_LOSS = 300;
input int MULTIPLIER_VOLUME = 2;
input double VOLUME = 0.01;
input int PERIOD_FI = 13;
input double CANDLE_POINTS = 300;
input double MIN_BALANCE = 0;

POWER  LOCK_IN_LOSS = OFF;
POWER USE_MAGIC_NUMBER = ON;
double PONTUATION_ESTIMATE = 500;
int NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
double ACTIVE_VOLUME = VOLUME;

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 

ORIENTATION orientMacro = MEDIUM;
int periodAval = 4, countRobots = 0, countTicks = 0   , countCandles = 0;
int WAIT_NEW_CANDLE = 0;
ulong robots[];

MqlRates candleMacro;
double averages[], averages8[], averages20[], averages80[], averages200[], MACD[], MACD5[], CCI[], FI[], VOL[], pointsMacro = 0;
double upperBand[], middleBand[], lowerBand[], upperBand5[], middleBand5[], lowerBand5[], RVI1[], RVI2[], RSI[];
int handleaverages[10], handleBand[2] ,handleICCI, handleVol, handleMACD[2], handleIRVI, handleFI, handleIRSI;

int MULTIPLIER_ROBOTS = 1, NUMBER_MAX_ROBOTS_ACTIVE = 0;
double BALANCE_ACTIVE = 0, INITIAL_BALANCE = 0, INITIAL_INVESTIMENT_ACTIVE = 0, INITIAL_INVESTIMENT = 0;
ORIENTATION bestOrientation = MEDIUM;
POWER lockBuy = OFF, lockSell = OFF;
int countBuy = 0, countSell = 0;
double EXPONENTIAL_VOLUME_ITERATOR = 100;
bool LOCK_ROBOTS = false;
int qtdBuyers = 0,  qtdBuyersWon = 0, qtdSellers = 0, qtdSellersWon = 0, qtdSellersLoss = 0, qtdBuyersLoss = 0;

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "btnCloseBuy"){
         closeAllPositionsByType(POSITION_TYPE_BUY);
      }
      if(sparam == "btnCloseSell"){
         closeAllPositionsByType(POSITION_TYPE_SELL);
      }
      
      if(sparam == "btnCloseAll"){
         closeAll();
         closeOrdersByDuration(0);
      }
      if(sparam == "btnMoveStop"){
         int pos = PositionsTotal() - 1;
         for(int i = pos; i >= 0; i--)  {
            activeStopMovelPerPoints(50, i);
         }
      }
      if(sparam == "btnBuy"){
         ulong magic = MAGIC_NUMBER + 6000;
         for(int i = 0; i < NUMBER_ROBOTS; i++){
            magic = magic + i;
            realizeDeals(BUY, VOLUME, STOP_LOSS, TAKE_PROFIT, magic);
         }
      }
      if(sparam == "btnSell"){
         ulong magic = MAGIC_NUMBER + 6000;
         for(int i = 0; i < NUMBER_ROBOTS; i++){
            magic = magic + i;
            realizeDeals(SELL, VOLUME, STOP_LOSS, TAKE_PROFIT, magic);
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
      }
      if(sparam == "btnLockSell"){
         if(lockSell == ON){
            lockSell = OFF;
         }else{
            lockSell = ON;
         }
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
      }
      
      if(sparam == "btnUpTakeBuy"){
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
      }
   }
}

int OnInit(){
      createButton("btnCloseBuy", 20, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Compras", clrWhite, clrRed, clrRed, false);
      createButton("btnCloseSell", 230, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Vendas", clrWhite, clrRed, clrRed, false);
      createButton("btnCloseAll", 440, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
      createButton("btnCloseProfit", 20, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar com lucro.", clrWhite, clrRed, clrRed, false);
      createButton("btnLockBuy", 230, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Travar Comprar", clrWhite, clrBlue, clrBlue, false);
      createButton("btnLockSell", 440, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Travar Venda", clrWhite, clrBlue, clrBlue, false);
      createButton("btnMoveStop", 20, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Mover Stops", clrWhite, clrBlue, clrBlue, false);
      createButton("btnBuy", 230, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Criar " + IntegerToString(NUMBER_ROBOTS) +" Robôs de Compra", clrWhite, clrBlue, clrBlue, false);
      createButton("btnSell", 440, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Criar " + IntegerToString(NUMBER_ROBOTS) +" Robôs de Venda", clrWhite, clrBlue, clrBlue, false);
      createButton("btnDoubleVol", 20, 250, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Multiplicar Volume por 2", clrWhite, clrBlue, clrBlue, false);
      createButton("btnDivVol", 230, 250, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Dividir Volume por 2", clrWhite, clrBlue, clrBlue, false);
      createButton("btnResetVol", 440, 250, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Resetar Volume", clrWhite, clrBlue, clrBlue, false);
      createButton("btnLockRobots", 20, 200, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Travar robôs", clrWhite, clrBlue, clrBlue, false);
      createButton("btnUpTakeBuy", 230, 200, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "+100 Pts Take na Compra", clrWhite, clrGreen, clrGreen, false);
      createButton("btnDownTakeBuy", 440, 200, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "-100 Pts Take na Compra", clrWhite, clrGreen, clrGreen, false);
      createButton("btnUpStopBuy", 20, 150, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "+100 Pts Stop na Compra", clrWhite, clrGreen, clrGreen, false);
      createButton("btnDownStopBuy", 230, 150, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "-100 Pts Stop na Compra", clrWhite, clrGreen, clrGreen, false);
    
      createButton("btnUpTakeSell", 440, 150, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "+100 Pts Take na Venda", clrWhite, clrGreen, clrGreen, false);
      createButton("btnDownTakeSell", 20, 100, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "-100 Pts Take na Venda", clrWhite, clrGreen, clrGreen, false);
      createButton("btnUpStopSell", 230, 100, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "+100 Pts Stop na Venda", clrWhite, clrGreen, clrGreen, false);
      createButton("btnDownStopSell", 440, 100, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "-100 Pts Stop na Venda", clrWhite, clrGreen, clrGreen, false);
     
      handleFI = iForce(_Symbol,PERIOD_H4, PERIOD_FI ,MODE_SMA,VOLUME_TICK);
      handleaverages[0] = iMA(_Symbol,PERIOD_H4, 8, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[1] = iMA(_Symbol,PERIOD_H4, 20, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[2] = iMA(_Symbol,PERIOD_H4, 80, 0, MODE_SMA, PRICE_CLOSE);
      handleaverages[3] = iMA(_Symbol,PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);
      handleVol = iVolumes(_Symbol,PERIOD_H4,VOLUME_TICK);
      BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
      INITIAL_BALANCE = BALANCE_ACTIVE;
      INITIAL_INVESTIMENT_ACTIVE = BALANCE_ACTIVE;
      INITIAL_INVESTIMENT = BALANCE_ACTIVE;
      NUMBER_MAX_ROBOTS_ACTIVE = NUMBER_MAX_ROBOTS;
      updateNumberRobots();
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
   int copiedPrice = CopyRates(_Symbol,_Period,0,periodAval,candles);
   if(copiedPrice == periodAval){
      double spread = candles[periodAval-1].spread;
      if(hasNewCandle()){
         WAIT_NEW_CANDLE--;
         //if(countCandles <= 0){
         //}
         countCandles--;
      }else{
         if(BALANCE_ACTIVE > MIN_BALANCE){
            if(LOCK_ROBOTS == false){
               if(WAIT_NEW_CANDLE <= 0){
                  Print("Robo executando");
                  if(countTicks <= 0){
                     toNegociate(spread);
                     countTicks = COUNT_TICKS;
                     updateNumberRobots();
                     moveAllPositions(spread);
                  }
                  countTicks--;
               }
            }else{
               closeOrdersByDuration(0);
            } 
         }else{
            closeOrdersByDuration(0);
         } 
            
         ORIENTATION orientFI = verifyForceIndex();
         showComments(orientFI);
      }
   }
}

void showComments(ORIENTATION orientFI){
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   Comment(
         " Total de robôs Disponiveis: ", (NUMBER_MAX_ROBOTS_ACTIVE - PositionsTotal()),
         " Total de robôs ativos: ", (PositionsTotal()), 
         " Saldo: ", DoubleToString(BALANCE_ACTIVE + profit, 2),
         " Lucro Atual: ", DoubleToString(profit, 2),
         " Robôs de Compra: ", countBuy,
         " Robôs de Venda: ", countSell,
         " Melhor Orientação: ", verifyPeriod(bestOrientation),
         " Orientação FI: ", verifyPeriod(orientFI),
         " Compra Travada: ", verifyPower(lockBuy),
         " Venda Travada: ", verifyPower(lockSell),
         " Robôs Travados: ", LOCK_ROBOTS,
         " Volume: ", ACTIVE_VOLUME);
}

void updateNumberRobots(){
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
   
   if(EXPONENTIAL_VOLUME == ON){
      
     if((BALANCE_ACTIVE+profit) / INITIAL_BALANCE >= 2){
         MULTIPLIER_ROBOTS++;
         INITIAL_BALANCE = BALANCE_ACTIVE+profit;
         ACTIVE_VOLUME *= 2;
         NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
      }
      
      
      if(INITIAL_BALANCE >= INITIAL_INVESTIMENT_ACTIVE * NUMBER_ROBOTS){
         ACTIVE_VOLUME = VOLUME;
         NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS_ACTIVE + NUMBER_ROBOTS ;
         NUMBER_MAX_ROBOTS_ACTIVE += NUMBER_ROBOTS;
         INITIAL_INVESTIMENT_ACTIVE = INITIAL_BALANCE;
      }
      
   }
   
   if(EXPONENTIAL_ROBOTS == ON){  
      if(POINTS_TO_CLOSE > 0){
         if(profit > 0 && profit > POINTS_TO_CLOSE * ACTIVE_VOLUME){
            closeAll();
         }else if(profit < 0 && MathAbs(profit) > POINTS_TO_CLOSE * ACTIVE_VOLUME ){
            if(ACTIVE_VOLUME / 2 < 0.01){
             ACTIVE_VOLUME /= 0.01;
            }else{
             ACTIVE_VOLUME /= 2;
            }
            closeAll();
         }
      }
      
      if(profit > 0){
         if(NUMBER_MAX_ROBOTS_ACTIVE > NUMBER_ROBOTS_ACTIVE){
            NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS_ACTIVE + NUMBER_ROBOTS ;
            Print("Adicionando novos robos: " + IntegerToString(NUMBER_ROBOTS_ACTIVE));
         }else{
            EXPONENTIAL_VOLUME_ITERATOR = 100;
            Print("Maximo de robôs permitidos ");
            
         }
      }else  if(profit < 1 && (MathAbs(profit) >  (INITIAL_INVESTIMENT_ACTIVE * ACTIVE_VOLUME))){
          //NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS_ACTIVE - NUMBER_ROBOTS ;
          NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
          
          if(NUMBER_ROBOTS_ACTIVE <=0){
            NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
          }
          Print("Removendo robos: " + IntegerToString(NUMBER_ROBOTS_ACTIVE));
      }
   }else{
      NUMBER_ROBOTS_ACTIVE = NUMBER_ROBOTS;
   }
   
   
   ArrayResize(robots, NUMBER_ROBOTS_ACTIVE + 2);
   for(int i = 0; i < NUMBER_ROBOTS_ACTIVE; i++)  {
      robots[i] = MAGIC_NUMBER + i; 
   }
}

void toNegociate(double spread){
      MqlRates actualCandle = candles[periodAval-1];
      MqlRates lastCandle = candles[periodAval-2];
      
    // showComments(orientFI);
     double stop = STOP_LOSS * 3;
     double take = TAKE_PROFIT * 3;
     if(bestOrientation == MEDIUM ){
         if( lockBuy == ON){
            executeOrderByRobots(DOWN, ACTIVE_VOLUME, stop , take );
         }
         else if( lockSell == ON){
            executeOrderByRobots(UP, ACTIVE_VOLUME, stop , take );
         }
         else if( lockSell == OFF && lockBuy == OFF && PositionsTotal() < 6){
            executeOrderByRobots(UP, ACTIVE_VOLUME, stop , take);
            executeOrderByRobots(DOWN, ACTIVE_VOLUME, stop, take);
         }
     } else{
         ORIENTATION orientFI = verifyForceIndex();
         if( lockSell == OFF && bestOrientation == DOWN){
            if(orientFI == bestOrientation){
               executeOrderByRobots(DOWN, ACTIVE_VOLUME * (MULTIPLIER_VOLUME < 1 ? 1 : MULTIPLIER_VOLUME), stop, take);
            }else{
               executeOrderByRobots(DOWN, ACTIVE_VOLUME, stop, take);
            }
         }
         else if( lockBuy == OFF && bestOrientation == UP){
            if(orientFI == bestOrientation){
               executeOrderByRobots(UP, ACTIVE_VOLUME * (MULTIPLIER_VOLUME < 1 ? 1 : MULTIPLIER_VOLUME), stop, take);
            }else{
               executeOrderByRobots(UP, ACTIVE_VOLUME, stop, take);
            }
         }
     }
      
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


void executeOrderByRobots(ORIENTATION orient, double volume, double stop, double take , bool order = false){
  if(countRobots < NUMBER_ROBOTS_ACTIVE){
   if(!hasPositionOpen((int)robots[countRobots])){
      if(countRobots > NUMBER_ROBOTS){
        // stop = (stop + 10 * countRobots);
       // take =TAKE_PROFIT;
      }
      if(order){
         double limitPrice = candles[periodAval-1].close;
         if(orient == UP){
            limitPrice = limitPrice - (ORDER_LIMIT_POINT * _Point);
         }else if(orient == DOWN){
            limitPrice = limitPrice + (ORDER_LIMIT_POINT * _Point);
         }
         toBuyOrToSellOrders(orient, volume, limitPrice, (stop), (take), robots[countRobots]);
      }else{
         toBuyOrToSell(orient, volume, (stop), (take), robots[countRobots]);
      }
   }
  }
  countRobots = PositionsTotal() + OrdersTotal();
}

void moveAllPositions(double spread){
   int pos = PositionsTotal() - 1;
   double  average[];
   
   for(int i = pos; i >= 0; i--)  {
      if(hasPositionOpen(i)){
         if(ACTIVE_MOVE_STOP == ON){
            activeStopMovelPerPoints(PONTUATION_MOVE_STOP+spread, i);
         }
         if(ACTIVE_MOVE_TAKE == ON){
            moveTakeProfit(i);
         }
      }
   }
   
   closeOrdersByDuration(ORDER_DURATION);
   decideToCreateOrDeleteRobots();
   if(pos <= 0){
      bestOrientation = MEDIUM;
   }
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


void  decideToCreateOrDeleteRobots(){
   int countLossSell = 0, countLossBuy = 0;
   int pos = PositionsTotal() - 1;
   double  average[];
   double profitBuy = 0;
   double profitSell = 0;
   countBuy = 0;
   countSell = 0;
   qtdBuyers = 0;
   qtdBuyersWon = 0;
   qtdBuyersLoss = 0;
   qtdSellers = 0;
   qtdSellersWon = 0;
   qtdSellersLoss = 0;
   
   
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
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT); 
            double pointsProfit =  MathAbs(profit / ACTIVE_VOLUME);
            double pointsTake = calcPoints(entryPrice, tpPrice);
            double pointsSL = calcPoints(entryPrice, slPrice);
            newTpPrice = tpPrice;
            
             if(type == POSITION_TYPE_BUY ){ 
                  qtdBuyers++; 
                  countBuy++;
                  profitBuy += profit;
                  
                  if(profit >= 0 ){
                     qtdBuyersWon++; 
                  }else{
                     qtdBuyersLoss++;
                     moveStopOrTake(type, true, position, 5);
                     moveStopOrTake(type, false, position, -5);
                  }
             }
             else if(type == POSITION_TYPE_SELL ){
                  qtdSellers++; 
                  countSell++;
                  profitSell += profit;
                  
                  if(profit >= 0 ){
                     qtdSellersWon++; 
                  }else{
                     qtdSellersLoss++;
                     moveStopOrTake(type, true, position, -5);
                     moveStopOrTake(type, false, position, 5);
                  }
            }
            
            long now = TimeCurrent() ;
            if(profit < 0 &&  DURATION_POSITION_IN_LOSS > 0 && (time + DURATION_POSITION_IN_LOSS) < now){
               closeBuyOrSell(position);
            }
         }
      }
   }
  
   MqlRates actualCandle = candles[periodAval-1];
   ORIENTATION orientCandle = verifyValidCandle(actualCandle, CANDLE_POINTS);
   double profit2 =  AccountInfoDouble(ACCOUNT_PROFIT);
   ORIENTATION orientAverages = verifyOrientationAverage(candles[periodAval-1].close);
   if(profitBuy  > 0 && profitSell <= 0 ){
      if( lockBuy == OFF){
         if( orientAverages != DOWN ){
            bestOrientation = UP;
            executeOrderByRobots(UP, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT, ORDER);
         }
      }
   }else if(profitSell >  0 && profitBuy <= 0){
      if( lockSell == OFF){
         if( orientAverages != UP){
            bestOrientation = DOWN;
            executeOrderByRobots(DOWN, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT, ORDER);
         }
     }
   }else if(profitSell < 0 && profitBuy < 0){
      bestOrientation = MEDIUM;
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
            double pointsProfit =  MathAbs(profit / ACTIVE_VOLUME);
            double pointsTake = calcPoints(entryPrice, tpPrice);
            double pointsSL = calcPoints(entryPrice, slPrice);
            newTpPrice = tpPrice;
            
            if(profit > 0){
              newSlPrice = slPrice;
              if(pointsProfit >= pointsTake * PERCENT_MOVE / 100 ){
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

void  activeStopMovelPerPoints(double points, int position = 0){
   double newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      PositionSelectByTicket(PositionGetTicket(position));
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double tpPrice = PositionGetDouble(POSITION_TP);
         double slPrice = PositionGetDouble(POSITION_SL);
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double entryPoints = 0, pointsInversion =  MathAbs(profit / ACTIVE_VOLUME);
         double pointsTake = calcPoints(entryPrice, tpPrice);
         bool modify = false, inversion = false;
         ORIENTATION orient = MEDIUM;
         newSlPrice = slPrice;
         points = points < pointsTake ? points : pointsTake;
         
         double mov = (points * PERCENT_MOVE / 100 * _Point);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
            //tpPrice = NormalizeDouble((tpPrice + (points * _Point)), _Digits);
            if(slPrice >= entryPrice ){
               entryPoints = calcPoints(slPrice, currentPrice);
               newSlPrice = NormalizeDouble((slPrice + mov), _Digits);
               modify = true;
            }else if(currentPrice > entryPrice + mov){
               entryPoints = calcPoints(entryPrice, currentPrice);
               newSlPrice = entryPrice;
               modify = true;
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
          //  tpPrice = NormalizeDouble((tpPrice - (points * _Point)), _Digits);
            if(slPrice <= entryPrice ){
               entryPoints = calcPoints(slPrice, currentPrice);
               newSlPrice = NormalizeDouble((slPrice - mov), _Digits);
               modify = true;
            }else if(currentPrice < entryPrice - mov){
               entryPoints = calcPoints(entryPrice, currentPrice);
               newSlPrice = entryPrice;
               modify = true;
            }
         }
            
         if(modify == true && entryPoints != 0 && entryPoints >= points){
            tradeLib.PositionModify(PositionGetTicket(position), newSlPrice, tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido");
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
      ulong ticket = OrderGetTicket(position);
      if(hasOrderOpen(ticket)){
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
         double slPrice = PositionGetDouble(POSITION_SL);
         double tpPrice = PositionGetDouble(POSITION_TP);
         double newTP = tpPrice + (points * _Point);
         double newSl = slPrice + (points * _Point);
            
         if(PositionGetInteger(POSITION_TYPE) == type){
            if(stop){
              tradeLib.PositionModify(ticket, newSl,tpPrice);         
            }else{
               tradeLib.PositionModify(ticket, slPrice,newTP);
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
      if(_Digits == 3){
         borders.min = (stopLoss * 1000);
         borders.max = (takeProfit * 1000);  
      }else{
         borders.min = NormalizeDouble((stopLoss * _Point), _Digits);
         borders.max = NormalizeDouble((takeProfit * _Point), _Digits); 
      }
   }
   
   return borders;
}


void toBuyLimitOrder(double volume, double limitPrice, double stopLoss, double takeProfit, datetime duration){
   double stopLossNormalized = NormalizeDouble((limitPrice - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((limitPrice + takeProfit), _Digits);
   tradeLib.BuyLimit(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration);   
  
   if(verifyResultTrade()){
      Print("Compra Limitada realizada.");
   }
}

void toSellLimitOrder(double volume, double limitPrice, double stopLoss, double takeProfit, datetime duration){
   double stopLossNormalized = NormalizeDouble((limitPrice + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((limitPrice - takeProfit), _Digits);
   tradeLib.SellLimit(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
  
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

bool realizeDealsOrders(TYPE_NEGOCIATION typeDeals, double volume, double limitPrice, double stopLoss, double takeProfit, ulong magicNumber, datetime duration){
   if(typeDeals != NONE){
   
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
    //  if(hasPositionOpen() == false) {
         if(typeDeals == BUY){ 
            toBuyLimitOrder( volume,limitPrice, borders.min, borders.max, duration);
         }
         else if(typeDeals == SELL){
            toSellLimitOrder( volume,limitPrice, borders.min, borders.max, duration);
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

bool verifyMagicNumber(int position = 0, ulong magicNumberRobot = 0){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      
     // if(magicNumberRobot == 0){
     //    magicNumberRobot = MAGIC_NUMBER;
     // }
      
      if(USE_MAGIC_NUMBER == OFF){
         return true;
      }else if(magicNumber == magicNumberRobot){
         return true;
      }
   }
   
   return false;
   
}

bool toBuyOrToSellOrders(ORIENTATION orient, double volume, double limitPrice, double stopLoss, double takeProfit, ulong magicNumber, datetime duration = 0){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDealsOrders(typeDeal, volume, limitPrice, stopLoss, takeProfit, magicNumber, duration);
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
      if(verifyMagicNumber(i, magicNumber)){
          double profit = PositionGetDouble(POSITION_PROFIT);
          if(profit > 0){
            closeBuyOrSell(i);
          }
      } 
   }
}

bool hasOrderOpen(ulong ticket ){
    if(OrderSelect(ticket) == true) {
      return true;       
    }
    
    return false;
}

bool hasPositionOpen(int position ){
    string symbol = PositionGetSymbol(position);
    if(PositionSelect(symbol) == true) {
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
   int copiedPrice = CopyRates(_Symbol,_Period,0,numCandles,candles);
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
   int pos = PositionsTotal() - 1;
   
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
   int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
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

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}
