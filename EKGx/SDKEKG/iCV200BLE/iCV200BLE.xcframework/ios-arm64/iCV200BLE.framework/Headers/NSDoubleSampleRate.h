#pragma once
/////////////////////////////////////////////////////////////////////////
//实时三次样条插值
//说明：
//      返回值存在 int *ReturnValues 中。

///////////////////////////////////////////////////////////////////////////////////////
#if defined(__cplusplus)
class CDoubleSampleRate {
	int td;     //dt=差值点数+1
	int y0,y1,y2,y3;
	double y1t,y2t,y3t;
	double judge,judge1;
//	int Times;
//	short Numbers;
//	short *ReturnValues;
	short ReturnValues[2];
    void CalculateReturnValues(short CurrentValue);
//	short *GetData();
public:
	CDoubleSampleRate();
	virtual ~CDoubleSampleRate();
	void Init(double uVpb);
	short GetNumbers();
	short *GetDoubleSampleRateData(short xn);
};

class CMultiChannelDoubleSampleRate {
	short m_chnum;
	short **ReturnValues;
	short *YangReturnValues[2];
	CDoubleSampleRate *m_pDoubleSampleRate;
public:
	CMultiChannelDoubleSampleRate(short chnum);
	virtual ~CMultiChannelDoubleSampleRate();
	void Init(double uVpb);
	short GetNumbers();
	short **GetDoubleSampleRateData(short *xn);
	short **GetData();
};
#endif
