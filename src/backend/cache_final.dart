
import "dart:io";
import "dart:async";
import "dart:convert";
import 'dart:math';
///cache start//////////////////////////////

class solve{
  static var datacache;
  static var inscache;
  static int row = 8,
    col = 8,
    size = 64,
    stop=0;
static Set<int> INScold={};
static Set<int> MEMcold={};
static Set<int> INSconflict={};
static Set<int> MEMconflict={};
static int pc = 0,count=0,btarget=0;
 static bool 
      knob1=true,
      knob2=true,
      running=true,
      isBranchtaken=false,
      loadHazard=false;
 static List n=[];
 static final RF = List<int>.filled(32, 0);
 static final b = List<int>.filled(32, 0);
 static final im = List<int>.filled(32, 0);
 static final t = List<int>.filled(32, 0);
 static final if_de=List<int>.filled(2, 0);
 static final t1=List<int>.filled(2, 0);
 static final de_ex =List<int>.filled(13, 0);//pc,instruction,op2,op1,immediate,branchtarget,op2select,aluop,branchselect,resultselect,memop,rfwrite,isbranch
 static final t2 =List<int>.filled(13, 0);
 static final ex_ma = List<int>.filled(9, 0);//pc,instruction,aluresult,op2,memop,resultselect,rfwrite,isbranch,immediate
 static final t3 = List<int>.filled(9, 0);
 static final ma_wb = List<int>.filled(5, 0);//pc,instruction,result,rfwrite,isbranch
 static final t4 = List<int>.filled(5, 0);
 static Map<int, int> MEM = Map<int, int>();
 static Map<int,int> INS=Map<int,int>();
 static List <BTB> buffer=[];
  //|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 static void dec2bin(int value) {
     if (value < 0) value = (1 << 32) + value;

    for (int i = 0; i < 32; i++) {
      t[i] = 0;
    }

    int i = 0;
    while (value > 0 && i <= 31) {
      t[i] = value % 2;
      double next = value / 2;
      value = next.toInt();
      i++;
    }
  }

 static int comp2() {

    int c = t[31];
    if (c == 1) {
      for (int i = 0; i <= 31; i++) {
        if (t[i] == 1)
          t[i] = 0;
        else
          t[i] = 1;
      }
      int i = 0;
      while (i <= 31 && t[i] == 1) {
        t[i] = 0;
        i++;
      }
      if (i <= 31) {
        t[i] = 1;
      }
    }
    int sum = 0;
    for (int i = 31; i >= 0; i--) {
      sum = (2 * sum) + t[i];
    }
    if (c == 1) {
      sum = (-1) * sum;
    }
    return sum;
  }

 static int lw(int Eaddress) {
    
    return datacache.getnumber(Eaddress,false,0);
  }

 static int lb(int Eaddress, int index) {
    int element = datacache.getnumber(Eaddress,false,0);
    int data = ((element >> (8 * index)) & 0xFF);
    for (int i = 0; i <= 7; i++) {
      t[i] = (data >> i) & 1;
    }
    for (int i = 8; i <= 31; i++) {
      t[i] = t[7];
    }
    return comp2();
  }

 static int lh(int Eaddress, int index) {
    int element = datacache.getnumber(Eaddress,false,0);
    int data = ((element >> (8 * index)) & 0xFFFF);
    for (int i = 0; i <= 15; i++) {
      t[i] = (data >> i) & 1;
    }
    for (int i = 16; i <= 31; i++) {
      t[i] = t[15];
    }
    return comp2();
  }

 static void sb(int Eaddress, int index) {
    int datain=ex_ma[3];
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2];}

    int element = MEM[Eaddress]??0;
    for (int i = 0; i <= 31; i++) {
      t[i] = (element >> i) & 1;
    }
    index = 8 * index;
    for (int i = 0; i <= 7; i++) {
      t[index] = (datain >> i) & 1;
      index = index + 1;
    }
    int temp=datacache.getnumber(Eaddress,true,comp2());
  }

 static void sh(int Eaddress, int index) {
    int datain=ex_ma[3];
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2];}

    int element = MEM[Eaddress]??0;
    for (int i = 0; i <= 31; i++) {
      t[i] = (element >> i) & 1;
    }
    index = 8 * index;
    for (int i = 0; i <= 15; i++) {
      t[index] = (datain >> i) & 1;
      index = index + 1;
    }
    int temp=datacache.getnumber(Eaddress,true,comp2());
  }

 static void sw(int Eaddress) {
    int datain=ex_ma[3];
    if(src2Hazard(ma_wb[1], ex_ma[1]) && knob2==true){
      datain=ma_wb[2]; }
    int temp=datacache.getnumber(Eaddress,true,datain);
  }

 static void fetch() {
     t1[0]=pc;t1[1]=inscache.getnumber(pc,false,0);
  }
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static  void decode_p(){
    //0,1,2,3,4,6,7,9,10,11
    t2[0]=if_de[0];t2[1]=if_de[1];
    t2[2]=RF[(t2[1]>>20)&0x1F];
    t2[3]=RF[(t2[1]>>15)&0x1F];
    if(knob2==true){
    //forwarding:
      if(src1Hazard(ma_wb[1],if_de[1])){t2[3]=ma_wb[2];}
      if(src2Hazard(ma_wb[1],if_de[1])){t2[2]=ma_wb[2];}
    //load-use hazard
     if(src2Hazard(de_ex[1],if_de[1]) && de_ex[1]&0x7F==3){loadHazard=true;}
     if(src1Hazard(de_ex[1],if_de[1]) && de_ex[1]&0x7F==3){loadHazard=true;}
    }

    //immediate
    for (int i = 0; i <= 31; i++) {
      im[i] = 0;b[i]=0;t[i]=0;
    }
    dec2bin(if_de[1]);
    for(int i=0;i<32;i++){b[i]=t[i];}
    ///i type
    if (if_de[1]&0x7F == 19 || if_de[1]&0x7F == 3 || if_de[1]&0x7F == 103) {
      for (int i = 20; i <= 31; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 12; i <= 31; i++) {
        im[i] = im[11];
      }
    }

    ///j type
    else if (if_de[1]&0x7F == 111) {
      for (int i = 12; i <= 19; i++) {
        im[i] = b[i];
      }
      im[11] = b[20];
      im[20] = b[31];
      for (int i = 21; i <= 30; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 21; i <= 31; i++) {
        im[i] = im[20];
      }
    }

    //u type
    else if (if_de[1]&0x7F == 55 || if_de[1]&0x7F == 23) {
      for (int i = 12; i <= 31; i++) {
        im[i] = b[i];
      }
    }

    ///b type
    else if (if_de[1]&0x7F == 99) {
      im[11] = b[7];
      im[12] = b[31];
      for (int i = 8; i <= 11; i++) {
        im[i - 7] = b[i];
      }
      for (int i = 25; i <= 30; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 13; i <= 31; i++) {
        im[i] = im[12];
      }
    }
    
    //s type
    else if(if_de[1]&0x7F==35)
    {
      for (int i = 7; i <= 11; i++) {
        im[i - 7] = b[i];
      }
      for (int i = 25; i <= 31; i++) {
        im[i - 20] = b[i];
      }
      for (int i = 12; i <= 31; i++) {
        im[i] = im[11];
      }
    }

    //immediate sign extension
    for (int i = 0; i < 32; i++) {
      t[i] = im[i];
    }
    t2[4] = comp2();

    //Rfwrite
    if(t2[1]&0x7F==51 || t2[1]&0x7F==19 || t2[1]&0x7F==3 || t2[1]&0x7F==111 || t2[1]&0x7F==103 || t2[1]&0x7F==55 || t2[1]&0x7F==23){t2[11]=1;}

    //resultselect
    if (t2[1]&0x7F == 3) t2[9] = 1; //load mode
    else if (t2[1]&0x7F == 111 || t2[1]&0x7F == 103) t2[9] = 2; //jal|jalr pc+4
    else if(t2[1]&0x7F==23)t2[9]=3;//auipc
    else if(t2[1]&0x7F==55)t2[9]=4;//lui

   //op2select
    if(t2[1]&0x7F==19 || t2[1]&0x7F==3 || t2[1]&0x7F==35 || t2[1]&0x7F==103)t2[6]=1;

   //MEmop
    if(t2[1]&0x7F==35)t2[10]=1;//for store

   //ALUOP
    if (t2[1]&0x7F == 99 || (t2[1]&0x7F == 51 && t2[1]>>12&0x7 == 0 && t2[1]>>25&0x7F == 32)) {
      t2[7] = 1;
    } //sub
    else if (t2[1]>>12&0x7 == 7 && (t2[1]&0x7F == 51 || t2[1]&0x7F == 19))
      t2[7] = 2; //and
    else if (t2[1]>>12&0x7 == 6 && (t2[1]&0x7F == 51 || t2[1]&0x7F == 19))
      t2[7] = 3; //or
    else if (t2[1]&0x7F == 51 && t2[1]>>12&0x7 == 4)
      t2[7] = 4; //xor
    if (t2[1]&0x7F == 51) {
      if (t2[1]>>12&0x7 == 1) t2[7] = 5; //sll
      else if (t2[1]>>12&0x7 == 5 && t2[1]>>25&0x7F == 32)
        t2[7] = 7; //sra
      else if(t2[1]>>12&0x7==5 && t2[1]>>25&0x7F==0)
        t2[7] = 6; //srl
      else if(t2[1]>>12&0x7==2)t2[7]=8;
    }   
  }
 static void execute() {
    //0,1,3,4,5,6,7,8
    //////////////////////pipelined////////////////////////////////////////
      t3[0]=de_ex[0];
      t3[1]=de_ex[1];
      t3[3]=de_ex[2];
      t3[4]=de_ex[10];
      t3[5]=de_ex[9];
      t3[6]=de_ex[11];
      t3[7]=de_ex[12];
      t3[8]=de_ex[4];
      
      int temp = de_ex[2];
      int op1=de_ex[3];
      if(knob2==true){
      //forwarding:
      if(src1Hazard(ex_ma[1],de_ex[1]) && ex_ma[1]&0x7F!=3){
        if(ex_ma[5]==0){
        op1=ex_ma[2];
      }
      else if(ex_ma[5]==2){
        op1=ex_ma[0]+4;
      }
      else if(ex_ma[5]==3){
        op1=ex_ma[0]+ex_ma[8];
      }
      else if(ex_ma[5]==4){
        op1=ex_ma[8];
      }}
      else if(src1Hazard(ma_wb[1],de_ex[1])){op1=ma_wb[2];}
    

      if(src2Hazard(ex_ma[1],de_ex[1]) && ex_ma[1]&0x7F!=3){
      if(ex_ma[5]==0){
        temp=ex_ma[2];t3[3]=ex_ma[2];
      }
      else if(ex_ma[5]==2){
        temp=ex_ma[0]+4;t3[3]=ex_ma[0]+4;
      }
      else if(ex_ma[5]==3){
        temp=ex_ma[0]+ex_ma[8];t3[3]=ex_ma[0]+ex_ma[8];
      }
      else if(ex_ma[5]==4){
        temp=ex_ma[8];t3[3]=ex_ma[8];
      }}
      else if(src2Hazard(ma_wb[1],de_ex[1])){temp=ma_wb[2];t3[3]=ma_wb[2];}
      //forwarding stopped
      }
    
    if (de_ex[6]==1) temp = de_ex[4];
    switch (de_ex[7]) {
      case 0:
        {
          t3[2] = temp + op1;
          if(t3[2]>2147483647){t3[2]=-2147483648+(t3[2]-2147483648);}
          else if(t3[2]< -2147483648){t3[2]=2147483647+(2147483649+t3[2]);}
        }
        break;

      case 1:
        {
          t3[2] = op1 - temp;
          if(t3[2]>2147483647){t3[2]=-2147483648+(t3[2]-2147483648);}
          else if(t3[2]< -2147483648){t3[2]=2147483647+(2147483649+t3[2]);}
        }
        break;

      case 2:
        {
          t3[2] = op1 & temp;
        }
        break;

      case 3:
        {
          t3[2] = op1 | temp;
        }
        break;

      case 4:
        {
          t3[2] = op1 ^ temp;
        }
        break;

      case 5:
        {
          t3[2]=op1;
          for(int i=0;i<temp;i++){
            t3[2]=t3[2]<<1;
            if(t3[2]>2147483647){t3[2]=-2147483648+(t3[2]-2147483648);}
            else if(t3[2]<-2147483648){t3[2]=2147483647+(2147483649+t3[2]);}
          }
        }break;
    //list use for srl
      case 6:
        {
          dec2bin(op1);
          int i = 0;
          for (; i <= 31 - temp && i<=31; i++) {
            t[i] = t[i + temp];
          }
          while (i <= 31) {
            t[i] = 0;
            i++;
          }
          t3[2] = comp2();
        }
        break;

      case 7:
        {
          t3[2] = op1 >> temp;
        }
        break;

      case 8:
        {
          if(op1<temp)t3[2]=1;
          else t3[2]=0;
        }break;
    }
    //branch
    btarget=pc+4;
    if(de_ex[1]&0x7F==99 || de_ex[1]&0x7F==111)btarget = de_ex[0] + de_ex[4];
    else if(de_ex[1]&0x7F==103)btarget=temp+op1;
    if (de_ex[1]&0x7F == 111 || de_ex[1]&0x7F==103) {t3[7] = 1;}
    if(de_ex[1]&0x7F==99){
      if ((de_ex[1]>>12)&0x7 == 0 && (op1==temp)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x7 == 1 && (op1!=temp)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x7 == 4 && (op1<temp)) t3[7] = 1;
      else if ((de_ex[1]>>12)&0x7 == 5 && (op1>=temp)) t3[7] = 1;
    }
    ////branch target buffer working///
    int index=0;
    if(de_ex[1]&0x7F==99 || de_ex[1]&0x7F==111 || de_ex[1]&0x7F==103){
      bool flag=false;
      for(int i=0;i<buffer.length;i++){
         if(buffer[i].address==de_ex[0]){flag=true;index=i;break;}
      }
      //adding to buffer
      if(flag==false){
        var block=new BTB(de_ex[0],btarget,false);
        if(de_ex[1]&0x7F==111 || de_ex[1]&0x7F==103)block.branchtaken=true;
        buffer.add(block);
        index=buffer.length-1;
       }
    }
    ////////branch target remaining////////////
    if(t3[7]==1 && (de_ex[1]&0x7F==99 || de_ex[1]&0x7F == 111 || de_ex[1]&0x7F==103)){isBranchtaken=true;}
    if(isBranchtaken==false){btarget=de_ex[0]+4;}
    if(btarget!=if_de[0] && de_ex[1]!=0){
      if(buffer[index].branchtaken==false){buffer[index].branchtaken=true;}
      else buffer[index].branchtaken=false;
    }
    isBranchtaken=false;

  }
 static void memory() {
    //pipelined// 
    if(knob1==true){
      t4[0]=ex_ma[0];t4[1]=ex_ma[1];t4[3]=ex_ma[6];t4[4]=ex_ma[7];
      int Eaddress = ex_ma[2] - (ex_ma[2] % 4);
      int index = ex_ma[2] % 4;
      for (int i = 0; i < 32; i++) {
      t[i] = 0;
    }
    if ((ex_ma[4] == 0) && (ex_ma[1]&0x7F==3)) {
     
      if ((ex_ma[1]>>12)&0x3 == 0) {
        t4[2]=lb(Eaddress, index);
      } else if ((ex_ma[1]>>12)&0x3 == 1) {
        t4[2]=lh(Eaddress, index);
      } else if((ex_ma[1]>>12)&0x3 == 2) {
        t4[2]=lw(Eaddress);
      }
    } else if(ex_ma[4]==1) {
      if ((ex_ma[1]>>12)&0x3 == 0) {
        sb(Eaddress, index);
      } else if ((ex_ma[1]>>12)&0x3 == 1) {
        sh(Eaddress, index);
      } else if((ex_ma[1]>>12)&0x3 == 2) {
        sw(Eaddress);
      }
    }
      
      if(ex_ma[5]==0){
        t4[2]=ex_ma[2];
      }
      else if(ex_ma[5]==2){
        t4[2]=ex_ma[0]+4;
      }
      else if(ex_ma[5]==3){
        t4[2]=ex_ma[0]+ex_ma[8];
      }
      else if(ex_ma[5]==4){
        t4[2]=ex_ma[8];
      }
    }
    
  }
 static void write_back(File f) {
       
        if( ma_wb[3]==1  &&   ((ma_wb[1]>>7)&0x1F)!=0 ){
          RF[(ma_wb[1]>>7)&0x1F]=ma_wb[2];
        }
        if(ma_wb[1]==1 ){swi_exit(f);}
  }
 static void transfer()
  {
    ////data forwarding////
    if(knob2==true){
      if(loadHazard==false){
      
      if(btarget!=if_de[0] && de_ex[1]!=0 && de_ex[1]!=19 ){pc=btarget;if_de[0]=0;if_de[1]=19;de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}}
      else {
                pc=pc+4;
                for(int i=0;i<buffer.length;i++){
                  if(buffer[i].address ==  (pc-4) && buffer[i].branchtaken==true){pc=buffer[i].branchtarget;}
                }
                 //if to de//
                 if_de[0]=t1[0];if_de[1]=t1[1];
                 //de to ex//
                 for(int i=0;i<13;i++){de_ex[i]=t2[i];}
           }
      }
        else{
            de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}loadHazard=false;}
    }
    ///no data forwarding///
    else{
      if(btarget!=if_de[0] && de_ex[1]!=0 && de_ex[1]!=19 ){pc=btarget;if_de[0]=0;if_de[1]=19;de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}}
      else {
        if(hazardDetect(de_ex[1])==false && hazardDetect(ex_ma[1])==false && hazardDetect(ma_wb[1])==false){
            pc=pc+4;
            for(int i=0;i<buffer.length;i++){
            if(buffer[i].address ==  (pc-4) && buffer[i].branchtaken==true){pc=buffer[i].branchtarget;}
            }
            //if to de//
            if_de[0]=t1[0];if_de[1]=t1[1];
            //de to ex//
            for(int i=0;i<13;i++){de_ex[i]=t2[i];}
        }
        else{
            de_ex[0]=0;de_ex[1]=19;for(int i=2;i<13;i++){de_ex[i]=0;}
        }

        }
    }

     //ma to wb//
     for(int i=0;i<9;i++){ex_ma[i]=t3[i];t3[i]=0;}
     for(int i=0;i<5;i++){ma_wb[i]=t4[i];t4[i]=0;}
     //temp//
     for(int i=0;i<13;i++){t2[i]=0;}
     t1[0]=0;t1[1]=0;
  }
 static void swi_exit(File f) {
    print(RF);
  
    print(count);
    print(datacache.misses);
    print(inscache.misses);
    //print(datacache.cache);
    //print(inscache.cache);
    exit(0);
  }
 static bool src1Hazard(int write,int read){
    int opcode1=write&0x7F,opcode2=read&0x7F;
    if(opcode1==35 || opcode1==99 || opcode1==0 || write==19){return false;}
    if(opcode2==111 || opcode2==55 || opcode2==23 || read==19){return false;}
    int src1=(read>>15)&0x1F,dest=(write>>7)&0x1F;
    if((src1!=0) && (src1 == dest)){return true;}
    return false;
  }
 static bool src2Hazard(int write,int read){
    bool hasrs2=false;
    int opcode1=write&0x7F,opcode2=read&0x7F;
    if(opcode1==35 || opcode1==99 || opcode1==0 || write==19){return false;}
    if(opcode2==111 || opcode2==55 || opcode2==23 || read==19){return false;}
    int src2=(read>>20)&0x1F,dest=(write>>7)&0x1F;
    if(opcode2==51 || opcode2==35 || opcode2==99){hasrs2=true;}
    if(hasrs2==true &&(src2!=0) && (src2 == dest)){return true;}
    return false;
  }
 static bool hazardDetect(int instruction){
    int opcode=instruction&0x7F;
    bool hasrs1=true,hasrs2=false;
    if(opcode==35 || opcode==99 || opcode==0 || instruction==19){return false;}
    if(if_de[1]&0x7F==111 || if_de[1]&0x7F==55 || if_de[1]&0x7F==23 || if_de[1]==19){return false;}
    int src1=(if_de[1]>>15)&0x1F,src2=(if_de[1]>>20)&0x1F,dest=(instruction>>7)&0x1F;
    if(if_de[1]&0x7F==51 || if_de[1]&0x7F==35 || if_de[1]&0x7F==99){hasrs2=true;}
    if(hasrs1==true && (src1!=0) && (src1 == dest)){return true;}
    else if(hasrs2==true &&(src2!=0) && (src2 == dest)){return true;}
    return false;
  }
 static void run_riscvsim(File f){
    while(running){
      fetch();
      if(stop>0){while(stop>0){count++;stop--;print("stall");}continue;}
      decode_p();
      execute();
      memory();
      if(stop>0){while(stop>0){count++;stop--;print("stall");}continue;}
      write_back(f);
      count++;
      transfer();
    }
  }

 static void load_progmem(){
    for(int i=0;i<n.length;i++)
    {
      String s=n[i];
      int address=0,instruct=0;
      int j=0;
      while(j<s.length && s.codeUnitAt(j)!=120){j++;}
      j++;
      while(j<s.length){
        int asc=s.codeUnitAt(j);
        if(asc==32)break;
        else{
          if(asc>=65)asc=asc-55;
          else asc=asc-48;
        }
        address=16*(address)+asc;
        j++;
      }
      while(j<s.length && s.codeUnitAt(j)!=120){j++;}
      j++;
      while(j<s.length){
        int asc=s.codeUnitAt(j);
        if(asc==32)break;
        else{
          if(asc>=65)asc=asc-55;
          else asc=asc-48;
        }
        instruct=16*(instruct)+asc;
        j++;
      }
      dec2bin(instruct);
      instruct=comp2();
      dec2bin(address);
      address=comp2();
      if(address>=0x10000000)
      MEM[address]=instruct;
      else
      INS[address]=instruct;
    }
  }

}
class Cache{
    int row=8,col=8,size=64; 
    int policy = 0, //random,lru,fifo
    mapping = 0,
    way = 2;
    var cache ;
    var dirty ;
    var status ;
    var filled ;
    var tag ;
    int accesses=0,
     hits=0,
     misses=0,
     coldmisses=0,
     conflictmisses=0,
     capacitymisses=0,
     penalty=20,
     hittime=1,
     totalstalls=0;
    bool INSorMEM=false;
    Cache(int row,int col,int policy,int mapping,int way){
      this.row=row;
      this.col=col;
      this.size=row*col;
      this.policy=policy;
      this.mapping=mapping;
      this.way=way;
    this.cache=List.generate(row, (i) => List.filled(col, 0, growable: false),growable: false);
    this.dirty = List.generate(row, (i) => 0, growable: false);
    this.status = List.generate(row, (i) => 0, growable: false);
    this.filled = List.generate(row, (i) => 0, growable: false);
    this.tag = List.generate(row, (i) => -1, growable: false);
    }

  void replace(int i, int block, int tagelement) {
  solve.stop=20;
  this.misses++;
  totalstalls+=penalty;
  if(INSorMEM==true && solve.INScold.contains(tagelement)==false)this.coldmisses++;
  else if(INSorMEM==false && solve.MEMcold.contains(tagelement)==false)this.coldmisses++;
  else{
     if(INSorMEM==true && solve.INSconflict.contains(tagelement)==true && this.mapping!=1)this.conflictmisses++;
     else if(INSorMEM==false && solve.MEMconflict.contains(tagelement)==true && this.mapping!=1)this.conflictmisses++;
     else this.capacitymisses++;
  }
  if(INSorMEM==true)solve.INScold.add(tagelement);
  else solve.MEMcold.add(tagelement);
  //|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
  int base = block * (4 * this.col);
  //if (dirty[i] == 1) writeBlock(i);
  tag[i] = tagelement;
  filled[i] = 1;
  dirty[i] = 0;
  if (policy == 1 || policy == 2) status[i] = this.col - 1;
  for (int j = 0; j < this.col; j++) {
    if(INSorMEM==false)
    cache[i][j] = solve.MEM[base + (4 * j)] ?? 0;
    else
    cache[i][j] = solve.INS[base + (4 * j)] ?? 0;
  }
}

int getnumber(int address,bool cacheop,int data) {
  this.accesses++;//|||||||||||||||||||||||||
  
  int block = address ~/ (4 * this.col);
  int offset = address & ((4 * this.col) - 1);
  offset = offset >> 2;
  int index = block & (this.row - 1);
  int tagelement = block ~/ (this.row);
  ///////////////1:-     DIRECT MAPPING     //////////////
  if (mapping == 0) {
    if (tag[index] != tagelement) {

      if(INSorMEM==true)solve.INSconflict.add((tag[index]*solve.row)+index);
      else solve.MEMconflict.add((tag[index]*solve.row)+index);

      replace(index, block, tagelement);}
    else this.hits++;//|||||||||||||||||||||||

    if(cacheop==true){
         solve.MEM[address]=data;
         cache[index][offset]=data;
         dirty[index]=1;
      }

    return cache[index][offset];
  }

  //fullyassociative
  else if (mapping == 1) {
    //////////////////////////////////////finding current block in cache////////////////////////////////
    int statusBit = 0;
    for (int i = 0; i < this.row; i++) {
      if (filled[i] == 1) statusBit++;
      if (tag[i] == block) {
        this.hits++;//|||||||||||||||||||||||||
        if (policy == 1) {
          statusBit = 0;
          for (int j = 0; j < this.row; j++) {
            if (status[j] > status[i]) status[j]--;
            if (filled[j] == 1) statusBit++;
          }
          status[i] = statusBit - 1;
        }
        if(cacheop==true){
         solve.MEM[address]=data;
         cache[i][offset]=data;
         dirty[i]=1;
        }

        return cache[i][offset];
      }
    }
    ///////////////////////////////////chaecking for empty space in cache for new block////////////////////////
    for (int i = 0; i < this.row; i++) {
      if (filled[i] == 0) {
        //add condition for new status number
        replace(i, block, block);
        status[i] = statusBit;
        if(cacheop==true){
         solve.MEM[address]=data;
         cache[i][offset]=data;
         dirty[i]=1;
      }
  
        return cache[i][offset];
      }
    }
    ///////////////////////////////////replacing a victim////////////////////////////////////////////////////////
    ///// 1:-        Random Policy
    if (policy == 0) {
      Random random = new Random();
      int i = random.nextInt(this.row);

      if(INSorMEM==true)solve.INSconflict.add(tag[i]);
      else solve.MEMconflict.add(tag[i]);

      replace(i, block, block);
      if(cacheop==true){
         solve.MEM[address]=data;
         cache[i][offset]=data;
         dirty[i]=1;
      }
 
      return cache[i][offset];
    }
    ///// 2:-        LRU policy or FIFO policy
    else {
      int index = 0;
      for (int i = 0; i < this.row; i++) {
        if (status[i] > 0)
          status[i]--;
        else
          index = i;
      }

      if(INSorMEM==true)solve.INSconflict.add(tag[index]);
      else solve.MEMconflict.add(tag[index]);

      replace(index, block, block);
      status[index] = this.row - 1;
      if(cacheop==true){
         solve.MEM[address]=data;
         cache[index][offset]=data;
         dirty[index]=1;
      }

      return cache[index][offset];
    }
  }
  ///////////////////////////////////////////SET associative////////////////////////////////////////
  else {
    int set = way * (block % (this.row ~/ way));
    tagelement = block ~/ (this.row ~/ way);
   // print("${address} ${set} ${tagelement} ${block} ${way}");
    int statusBit = 0;

    for (int i = set; i < set + way; i++) {
      if (filled[i] == 1) statusBit++;
      if (tag[i] == tagelement) {
        
        this.hits++;//|||||||||||||||||||||||||||||||||||||||||||
        if (policy == 1) {
          statusBit = 0;
          for (int j = set; j < set + way; j++) {
            if (status[j] > status[i]) status[j]--;
            if (filled[j] == 1) statusBit++;
          }
          status[i] = statusBit - 1;
        }
        if(cacheop==true){
         solve.MEM[address]=data;
         cache[i][offset]=data;
         dirty[i]=1;
        }

        return cache[i][offset];
      }
    }

    ///////////////////////////////////chaecking for empty space in cache for new block////////////////////////
    for (int i = set; i < set + way; i++) {
      if (filled[i] == 0) {
        //add condition for new status number
        replace(i, block, tagelement);
        status[i] = statusBit;
        if(cacheop==true){
         solve.MEM[address]=data;
         cache[i][offset]=data;
         dirty[i]=1;
      }
  
        return cache[i][offset];
      }
    }
    ///////////////////////////////////replacing a victim////////////////////////////////////////////////////////
    ///// 1:-        Random Policy
    if (policy == 0) {
      Random random = new Random();
      int i = set + random.nextInt(way);

      if(INSorMEM==true)solve.INSconflict.add((tag[i]*(this.row ~/ way))+set);
      else solve.MEMconflict.add((tag[i]*(this.row ~/ way))+set);

      replace(i, block, tagelement);
      if(cacheop==true){
         solve.MEM[address]=data;
         cache[i][offset]=data;
         dirty[i]=1;
      }
  
      return cache[i][offset];
    }
    //////2:-        LRU policy or FIFO policy
    else {
      int index = 0;
      for (int i = set; i < set + way; i++) {
        if (status[i] > 0)
          status[i]--;
        else
          index = i;
      }

      if(INSorMEM==true)solve.INSconflict.add((tag[index]*(this.row ~/ way))+set);
      else solve.MEMconflict.add((tag[index]*(this.row ~/ way))+set);

      replace(index, block, tagelement);
      status[index] = way - 1;
      if(cacheop==true){
         solve.MEM[address]=data;
         cache[index][offset]=data;
         dirty[index]=1;
      }
      
      return cache[index][offset];
    }
  }
  
}
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////cache end/////////////

class BTB{
  var address;
  var branchtarget;
  var branchtaken;
  BTB(int address,int branchtarget,bool branchtaken){
    this.address=address;
    this.branchtaken=branchtaken;
    this.branchtarget=branchtarget;
  }
}


//||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
  
void main() {
  solve.datacache=new Cache(8,2,2,2,8);
  solve.inscache=new Cache(8,2,2,2,8);
  solve.inscache.INSorMEM=true;
  var path='test.txt';
  var file= new File(path);
  List<String> str=file.readAsLinesSync();
  for(int i=0;i<str.length;i++)
  {solve.n.add(str[i]);}
  solve.RF[2]=2147483644;
  solve.buffer.add(new BTB(-1,-1,false));
  solve.load_progmem();
  solve.run_riscvsim(file);
  
}