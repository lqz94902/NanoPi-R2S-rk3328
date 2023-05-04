#!/bin/bash

rm /mnt/sda1/R2S/.Syslog/fan.txt        #����ɾ��fan.log

if [ ! -d /sys/class/pwm/pwmchip0 ]; then
    echo "this model does not support pwm."
    exit 1
fi

if [ ! -d /sys/class/pwm/pwmchip0/pwm0 ]; then
    echo -n 0 > /sys/class/pwm/pwmchip0/export
fi
sleep 1
while [ ! -d /sys/class/pwm/pwmchip0/pwm0 ];
do
    sleep 1
done
ISENABLE=`cat /sys/class/pwm/pwmchip0/pwm0/enable`
if [ $ISENABLE -eq 1 ]; then
    echo -n 0 > /sys/class/pwm/pwmchip0/pwm0/enable
fi
echo -n 50000 > /sys/class/pwm/pwmchip0/pwm0/period
echo -n 1 > /sys/class/pwm/pwmchip0/pwm0/enable

# max speed run 5s
echo -n 25000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
sleep 5
echo -n 49990 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

## ����������ͣ�¶�
temphigh=55000
templow=45000
# declare -a CpuTemps=(55000 43000 38000 32000)
# declare -a PwmDutyCycles=(1000 20000 30000 45000)

declare -a CpuTemps=(65000 60000 55000 $temphigh)     #�����Զ����ٽ��¶����飨65��,60��,55��,{$temphigh}�棩
declare -a PwmDutyCycles=(25000 30000 35000 45000)    #pwm�͵�ƽʱ�䣬���ڵ���ռ�ձȣ�ռ�ձ�=[period-PwmDutyCycles]/period��
#��Ӧ�ٽ��¶�ռ�ձȣ�50%,40%,30%,10%��
declare -a Percents=(50 40 30 10)

lognum=0

echo "* * * * * * * * * * * * * * * * *" >> /mnt/sda1/R2S/.Syslog/fan.txt
echo "* Temphigh=$temphigh  Templow=$templow *" >> /mnt/sda1/R2S/.Syslog/fan.txt
echo "* * * * * * * * * * * * * * * * *" >> /mnt/sda1/R2S/.Syslog/fan.txt
echo -e "\n" >> /mnt/sda1/R2S/.Syslog/fan.txt

while true
do
	temp=$(cat /sys/class/thermal/thermal_zone0/temp)
	INDEX=0
	FOUNDTEMP=0
	
	for i in 0 1 2 3; do
		if [ $temp -gt ${CpuTemps[$i]} ]; then
			DUTY=${PwmDutyCycles[$i]}
			PERCENT=${Percents[$i]}
      
      #������תд����־
      #echo "==============================" >> /mnt/sda1/R2S/.Syslog/fan.txt
      echo "No.$lognum" >> /mnt/sda1/R2S/.Syslog/fan.txt
      date >> /mnt/sda1/R2S/.Syslog/fan.txt
      echo "Temp: $temp, Duty: $DUTY, ${PERCENT}%" >> /mnt/sda1/R2S/.Syslog/fan.txt
      ((lognum++));
      
			break
    elif [ $temp -le $templow ]; then          #�¶ȵ���templowͣת
			DUTY=49990
			break
		fi	
	done
  
	echo -n $DUTY > /sys/class/pwm/pwmchip0/pwm0/duty_cycle;

	sleep 5;      #���ʱ��������λ���룩
done
