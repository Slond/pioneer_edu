## При создании программы автономного полёта коптер зависает на месте

Начиная с прошивки 6173 прекращена поддержка event Altitude Reached. Но Трик об этом не знает, и часто в функции callback прописывает этот ивент.
Из-за этого коптер не переходит на следующий блок кода.

Чтобы исправить ошибку, необходимо изменить **Ev.ALTITUDE_REACHED** на **Ev.TAKEOFF_COMPLETE**.
![image](https://user-images.githubusercontent.com/37597315/124445145-f6733180-dd87-11eb-8b93-6b91acd14eaf.png)
![image](https://user-images.githubusercontent.com/37597315/124445217-0723a780-dd88-11eb-9b0d-37004e9887fe.png)
