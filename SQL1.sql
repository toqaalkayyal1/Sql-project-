------------------------------1
SELECT P.PatientID, 
       (P.FirstName + ' ' + P.LastName) AS FULL_NAME,
       A.DoctorID,
       COUNT(*) AS VISITS_COUNT
FROM Patients P 
JOIN Appointments A ON P.PatientID = A.PatientID
GROUP BY P.PatientID, P.FirstName, P.LastName, A.DoctorID
HAVING COUNT(*) > 1;
----------------------------------------2
SELECT TOP 1
    d.DoctorID,
    d.FirstName,
    AVG(t.Cost) AS AverageTreatmentCost
FROM Doctors d
JOIN Appointments a
    ON d.DoctorID = a.DoctorID
JOIN Treatments t
    ON a.AppointmentID = t.AppointmentID
GROUP BY d.DoctorID, d.FirstName
ORDER BY AverageTreatmentCost DESC
---------------------------------------3

SELECT
    p.PatientID,
    P.[FirstName],
    SUM(t.Cost) AS TotalTreatmentCost
FROM Patients p
JOIN Appointments a
    ON p.PatientID = a.PatientID
JOIN Treatments t
    ON a.AppointmentID = t.AppointmentID
GROUP BY p.PatientID, p.FirstName
HAVING SUM(t.Cost) >
(
    SELECT AVG(TotalSpending)
    FROM
    (
        SELECT SUM(t2.Cost) AS TotalSpending
        FROM Appointments a2
        JOIN Treatments t2
            ON a2.AppointmentID = t2.AppointmentID
        GROUP BY a2.PatientID
    ) x
);
--------------------------- 4
SELECT D.DoctorID,(D.FirstName+' '+D.LastName) AS 'DR_NAME',COUNT(A.AppointmentID) AS'NUM_OF_APP'
FROM Doctors D JOIN Appointments A
ON D.DoctorID=A.DoctorID
GROUP BY D.DoctorID,D.FirstName,D.LastName
HAVING COUNT ( A.AppointmentID)>(
      SELECT  AVG( APPCOUNT*1)
      FROM( SELECT [DoctorID],COUNT(*) AS'APPCOUNT'
             FROM [dbo].[Appointments]
             GROUP BY [DoctorID]
             ) X
             );
--------------------------------5
WITH MonthlyAppointments AS
(
    SELECT
        MONTH(AppointmentDate) AS AppointmentMonth,
        COUNT(*) AS AppointmentCount
    FROM Appointments
    GROUP BY MONTH(AppointmentDate)
)
SELECT
    AppointmentMonth,
    AppointmentCount
FROM MonthlyAppointments
WHERE AppointmentCount =
(
    SELECT MAX(AppointmentCount)
    FROM MonthlyAppointments
);
------------------------------------6
SELECT  P.PatientID,(P.FirstName+' '+P.LastName) AS 'FULL_NAME',AVG(T.COST) OVER
( PARTITION BY P.PATIENTID
) AS 'AVG_TRET'
FROM Patients P
JOIN Appointments A ON P.PatientID=A.PatientID
JOIN Treatments T  ON A.AppointmentID=T.AppointmentID
-----------------------------------7
SELECT PatientID, AppointmentDate,LAG(AppointmentDate)OVER(
PARTITION BY PatientID
ORDER BY AppointmentDate) AS 'PREVIOUS_AppointmentDate'
FROM Appointments;
---------------------------------8
WITH RANKED AS
( SELECT 
PatientID, AppointmentID,AppointmentDate, ROW_NUMBER () OVER (PARTITION BY PatientID
ORDER BY AppointmentDate) AS 'RN'
FROM Appointments
)
SELECT PatientID, AppointmentID,AppointmentDate
FROM RANKED
WHERE RN=1;
-------------------------------9
SELECT P.PatientID,(P.FirstName+' '+P.LastName) AS 'FULL_NAME',
SUM(T.COST) AS PatientSpending,  SUM(t.Cost) * 100.0 /
        SUM(SUM(t.Cost)) OVER () AS PercentageOfTotalRevenue
FROM Patients P JOIN Appointments A ON P.PatientID=A.AppointmentID
 JOIN Treatments T ON A.AppointmentID=T.AppointmentID
 GROUP BY P.PatientID,P.FirstName,P.LastName;
 ----------------------------10
 SELECT
    (P.FirstName+' '+P.LastName) AS 'FULL_NAME',
    SUM(t.Cost) AS PatientSpending,
    SUM(SUM(t.Cost)) OVER () AS TotalRevenue,
    SUM(t.Cost) * 100.0 /
        SUM(SUM(t.Cost)) OVER () AS PercentageOfTotalRevenue
FROM Patients p
JOIN Appointments a
    ON p.PatientID = a.PatientID
JOIN Treatments t
    ON a.AppointmentID = t.AppointmentID
GROUP BY p.PatientID, p.FirstName,P.LastName
ORDER BY PatientSpending DESC;

 ---------------------------11
 SELECT P.PatientID, (P.FirstName+' '+P.LastName) AS 'FULL_NAME',
 COUNT (DISTINCT A.AppointmentID) AS'TOTALVISIT',
 SUM(T.COST) AS 'TotalSpending'
  FROM Patients P 
  JOIN Appointments A ON P.PatientID=A.PatientID
  JOIN Treatments T ON A.AppointmentID=T.AppointmentID
  GROUP BY P.PatientID,P.FirstName,P.LastName
  HAVING  COUNT (DISTINCT A.AppointmentID)>=3
  AND SUM(T.COST)>
  ( SELECT AVG(X.TotalSpending)
   FROM (   SELECT
               a2.PatientID,
               SUM(t2.Cost) AS TotalSpending
           FROM Appointments a2
           JOIN Treatments t2
               ON a2.AppointmentID = t2.AppointmentID
           GROUP BY a2.PatientID
       ) x
   );
------------------------------------12
WITH DoctorRevenue AS
(
    SELECT
        dep.DepartmentID,
        dep.DepartmentName,
        d.DoctorID,
        (D.FirstName+''+D.LastName) AS 'DR_NAME',
        COUNT( a.PatientID) AS 'NumberOfPatients',
        COUNT(DISTINCT a.AppointmentID) AS 'NumberOfAppointments',
        SUM(t.Cost) AS 'RevenueGenerated',
        ROW_NUMBER() OVER
        (
            PARTITION BY dep.DepartmentID
            ORDER BY SUM(t.Cost) DESC
        ) AS RevenueRank
    FROM Departments dep
    JOIN DoctorDepartments DE
        ON dep.DepartmentID = DE.DepartmentID
    JOIN Doctors D ON DE.DoctorID=D.DoctorID
    JOIN Appointments a
        ON d.DoctorID = a.DoctorID
    JOIN Treatments t
        ON a.AppointmentID = t.AppointmentID
    GROUP BY
        dep.DepartmentID,
        dep.DepartmentName,
        d.DoctorID,
        D.FirstName,
        D.LastName
)
SELECT
    DepartmentName,
    DR_NAME,
    RevenueRank
FROM DoctorRevenue
ORDER BY DepartmentName, RevenueRank;
----------------------------------13
SELECT
P.PatientID,(P.FirstName+' '+LastName) AS 'NAME',
COUNT(DISTINCT A.AppointmentID)AS 'TOTAL_VISIT',
COUNT(DISTINCT T.TreatmentID)AS 'TOTAL_TREATMENT',
COUNT(DISTINCT PR.PrescriptionID)AS 'TOTAL_PRESCRIPTION',
COALESCE( SUM(T.COST),0) AS'TOTAL_SPEND'
FROM 
Patients P LEFT JOIN Appointments A ON P.PatientID=A.PatientID
LEFT JOIN Treatments T ON A.AppointmentID=T.AppointmentID
LEFT JOIN Prescriptions PR ON T.AppointmentID=PR.AppointmentID
GROUP BY P.PatientID,P.FirstName,P.LastName
--------------------------------14
SELECT
    (SELECT COUNT(DISTINCT PatientID) FROM Patients) AS TotalPatients,

    (SELECT COUNT(DISTINCT DoctorID) FROM Doctors) AS TotalDoctors,

    (SELECT COUNT(DISTINCT AppointmentID) FROM Appointments) AS TotalAppointments,

    (SELECT COUNT(DISTINCT TreatmentID) FROM Treatments) AS TotalTreatments,

    (SELECT SUM(Cost) FROM Treatments) AS TotalRevenue,

    (SELECT SUM(Cost) FROM Treatments) * 1.0 /
    (SELECT COUNT(DISTINCT PatientID) FROM Patients) AS AverageRevenuePerPatient;