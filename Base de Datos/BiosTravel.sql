-- Script Obligatorio Segundo Año -- BIOS TRAVEL

Use Master
go

if exists(Select * FROM SysDataBases WHERE name='BiosTravel')
begin
	DROP DATABASE BiosTravel
end
go

Create Database BiosTravel
go

Use BiosTravel
go

-- CREACIÓN DE TABLAS -- LDD (Lenguaje de Definición de Datos) --

Create Table Empleados
(
	usuario varchar(15) primary key,
	passUsu varchar(10) not null check(LEN(passUsu) between 5 and 10 AND passUsu like '%[A-Za-z]%' AND passUsu like '%[0-9]%' AND passUsu like '%[^A-Za-z0-9]%'),
	nombreCompleto varchar(40) not null
)
go

Create Table Estados
(
	codigo varchar(4) primary key check(codigo like '[A-Za-z][A-Za-z][A-Za-z][A-Za-z]'),
	nombre varchar(25) not null,
	pais varchar(25) not null,
	activoE bit not null Default(1)
)
go

Create Table Vuelos
(
	codigo varchar(10) primary key check(LEN(codigo) = 10),
	fechaHoraP datetime not null check((fechaHoraP) > GETDATE()),
	fechaHoraL datetime not null,
	precioV float not null check((precioV) > 0),
	activoV bit not null Default(1),
	estadoPartidaC varchar(4) not null Foreign Key References Estados(codigo),
	estadoArriboC varchar(4) not null Foreign Key References Estados(codigo),
	check(fechaHoraL > fechaHoraP)
)
go

Create Table Hospedajes
(
	codigoInterno varchar(10) primary key check(codigoInterno not like '%[^A-Za-z ]%'),
	nombre varchar(30) not null,
	calle varchar(30) not null,
	localidad varchar(30) not null,
	precioH float not null check((precioH) > 0),
	tipoH varchar(13) not null check(tipoH in ('Hotel STD', 'Posada', 'All Inclusive')),
	activoH bit not null Default(1),
	estadoCodigo varchar(4) not null Foreign Key References Estados(codigo)
)
go

Create Table PaquetesViajes
(
	codigo int identity primary key,
	titulo varchar(25) not null,
	descripcion varchar(MAX) not null,
	cantidadDiasP int not null check((cantidadDiasP) >= 1),
	precioIndividual float not null check((precioIndividual) > 0),
	precioDosP float not null,
	precioTresP float not null,
	empleadoU varchar(15) not null Foreign Key References Empleados(usuario),
	vueloIC varchar(10) not null Foreign Key References Vuelos(codigo),
	vueloVC varchar(10) not null Foreign Key References Vuelos(codigo),
	estadoPVC varchar(4) not null Foreign Key References Estados(codigo),
	check(precioDosP > precioIndividual),
	check(precioTresP > precioIndividual),
	check(vueloIC <> vueloVC)
)
go

Create Table Incluyen
(
	codigoH varchar(10) Foreign Key References Hospedajes(codigoInterno),
	codigoPV int Foreign Key References PaquetesViajes(codigo),
	cantNoches int not null check((cantNoches) > 0),
	Primary Key (codigoH, codigoPV)
)
go

-- Usuario IIS --

USE master
GO

CREATE LOGIN [IIS APPPOOL\DefaultAppPool] FROM WINDOWS 
GO

USE BiosTravel
GO

CREATE USER [IIS APPPOOL\DefaultAppPool] FOR LOGIN [IIS APPPOOL\DefaultAppPool]
GO

--esto es por el EF 
exec sys.sp_addrolemember 'db_owner', [IIS APPPOOL\DefaultAppPool]
go

-- Creo roles y permisos en la base de datos
CREATE ROLE db_executor
go
GRANT EXECUTE TO db_executor
go

--- PROCEDIMIENTOS ALMACENADOS ---

-- Empleado --
CREATE PROCEDURE Logueo
@usu varchar(15),
@pass varchar(10)
as
Begin
	Select *
	From Empleados
	Where usuario = @usu AND passUsu = @pass
End
go

CREATE PROCEDURE NuevoUsuario
@usuario varchar(15),
@passUsu varchar(10),
@nomCompleto varchar(40)
as
Begin

	if exists(select * from Empleados where usuario = @usuario)
		return -1

	Declare @VarSentencia varchar(200)

	Begin Transaction

		-- primero: ingreso el usuario en la tabla
		Insert into Empleados (usuario, passUsu, nombreCompleto) Values (@usuario, @passUsu, @nomCompleto)

		if (@@ERROR <> 0)
		Begin
			Rollback TRAN
			return -2
		End

		-- segundo: creo el usuario de logueo
		Set @VarSentencia = 'CREATE LOGIN [' + @usuario + '] WITH PASSWORD = ' + QUOTENAME (@passUsu, '''')
		Exec (@VarSentencia) 

		if (@@ERROR <> 0)
		Begin
			Rollback TRAN
			return -3
		End

		-- tercero: creo usuario bd
		Set @VarSentencia = 'CREATE USER [' +  @usuario + '] From Login [' + @usuario + ']'
		Exec (@VarSentencia)
		
		if (@@ERROR <> 0)
		Begin
			Rollback TRAN
            return -4
        End

		-- cuarto: asigno rol de base de datos para ejecutar los sp
		Set @VarSentencia = 'ALTER ROLE db_executor Add Member [' + @usuario + ']'
		Exec (@VarSentencia)

		if (@@ERROR <> 0)
		Begin
			Rollback TRAN
			return -5
		End

		-- quinto: asigno rol de seguridad de base de datos
		Set @VarSentencia = 'ALTER ROLE db_securityadmin Add Member [' + @usuario + ']'
		Exec (@VarSentencia)

		if (@@ERROR <> 0)
		Begin
			Rollback TRAN
			return -6
		End

		-- sexto: asigno rol de logins a nivel de servidor
		Set @VarSentencia = 'ALTER SERVER ROLE securityadmin Add Member [' + @usuario + ']'
		Exec (@VarSentencia)

		if (@@ERROR <> 0)
		Begin
			Rollback TRAN
			return -7
		End

	Commit TRANSACTION

	return 1
End
go

CREATE PROCEDURE BuscarEmpleado
@usuario varchar(15)
as
Begin
	Select * from Empleados
	Where usuario = @usuario
End
go

CREATE PROCEDURE ModificarEmpleado
@usuario varchar(15),
@passUsu varchar(10),
@nombreCompleto varchar (40)
as
Begin
	if not exists(select * from Empleados where usuario = @usuario)
		return -1

	DECLARE @VarSentencia varchar(200)

	Begin Transaction

		UPDATE Empleados SET passUsu = @passUsu, nombreCompleto = @nombreCompleto
		where usuario = @usuario
			if @@ERROR != 0
				Begin
					Rollback Tran
					return -2
				End

		Set @VarSentencia = 'ALTER LOGIN [' + @usuario + '] WITH PASSWORD = ' + QUOTENAME (@passUsu, '''')
		Exec (@VarSentencia)
			if @@ERROR <> 0
				Begin
					Rollback Tran
					return -3
				End

	Commit Transaction

	return 1
End
go

CREATE PROCEDURE ListarEmpleados
as
Begin
	Select * from Empleados
End
go

-- Estados --
CREATE PROCEDURE AltaEstado
@codigo varchar(4),
@nombre varchar(25),
@pais varchar(25)
as
Begin
	if exists(select * from Estados where codigo = @codigo AND activoE = 1)
		return -1

	if exists(select * from Estados where codigo = @codigo AND activoE = 0)
		Update Estados SET nombre = @nombre, pais = @pais, activoE = 1
		where codigo = @codigo
			if @@ERROR <> 0
				return - 2		

	INSERT INTO Estados (codigo, nombre, pais) VALUES (@codigo, @nombre, @pais)
		if @@ERROR <> 0
			return -3

	return 1
End
go

CREATE PROCEDURE BajaEstados
@codigo varchar(4)
as
Begin
	if (not exists(Select * from Estados where codigo = @codigo))
		return -1

	-- baja logica si hay dependencias
	if (exists(Select * from Hospedajes where estadoCodigo = @codigo))
		Begin
			Update Estados Set activoE = 0 where codigo = @codigo
			return 1
		End
		
	if (exists(Select * from Vuelos where estadoArriboC = @codigo OR estadoPartidaC = @codigo))
		Begin
			Update Estados Set activoE = 0 where codigo = @codigo
			return 1
		End

	if (exists(Select * from PaquetesViajes where estadoPVC = @codigo))
		Begin
			Update Estados Set activoE = 0 where codigo = @codigo
			return 1
		End
	-- baja fisica si no hay dependencias
	else
		Begin
			Delete Estados where codigo = @codigo
			if (@@ERROR <> 0)
				return -2
			else
				return 1
		End
End
go

CREATE PROCEDURE ModificarEstado
@codigo varchar(4),
@nombre varchar(25),
@pais varchar(25)
as
Begin
	if not exists(select * from Estados where codigo = @codigo AND activoE = 1)
		return -1

	UPDATE Estados SET pais = @pais, nombre = @nombre where codigo = @codigo
		if @@ERROR != 0
			return - 2

	return 1
End
go

CREATE PROCEDURE BuscarTodosEstados
@codigo varchar(4)
as
Begin
	Select * from Estados
	Where codigo = @codigo
End
go

CREATE PROCEDURE BuscarEstados
@codigo varchar(4)
as
Begin
	Select * from Estados
	Where codigo = @codigo AND activoE = 1
End
go

CREATE PROCEDURE ListarEstados
as
Begin
	Select * from Estados where activoE = 1
End
go

-- Vuelo --
CREATE PROCEDURE AltaVuelo
@codigo varchar(10),
@fechaHoraP datetime,
@fechaHoraL datetime,
@precioV float,
@estadoPartidaC varchar(4),
@estadoArriboC varchar(4)
as
Begin
	if exists(select * from Vuelos where codigo = @codigo AND activoV = 1)
		return -1
	
	if not exists(select * from Estados where codigo = @estadoPartidaC AND activoE = 1)
		return -2

	if not exists(select * from Estados where codigo = @estadoArriboC AND activoE = 1)
		return -3

	if exists(select * from Vuelos where codigo = @codigo AND activoV = 0)
		Update Vuelos SET fechaHoraP = "fechaHoraP", fechaHoraL = @fechaHoraL, precioV = @precioV, estadoPartidaC = @estadoPartidaC, estadoArriboC = @estadoArriboC, activoV = 1
		where codigo = @codigo
			if @@ERROR <> 0
				return -4

	INSERT INTO Vuelos (codigo, fechaHoraP, fechaHoraL, precioV, estadoPartidaC, estadoArriboC) 
	VALUES (@codigo, @fechaHoraP, @fechaHoraL, @precioV, @estadoPartidaC, @estadoArriboC)
		if @@ERROR <> 0
			return -5

	return 1
End
go

CREATE PROCEDURE BajaVuelo
@codigo varchar(10)
as
Begin
	if (not exists(Select * from Vuelos where codigo = @codigo))
		return -1

	-- baja logica si hay dependencias
	if (exists(Select * from PaquetesViajes where vueloIC = @codigo OR vueloVC = @codigo))
		Begin
			Update Vuelos Set activoV = 0 where codigo = @codigo
			return 1
		End
	-- baja fisica si no hay dependencias
	else
		Begin
			Delete Vuelos where codigo = @codigo
			if (@@ERROR <> 0)
				return -2
			else
				return 1
		End
End
go

CREATE PROCEDURE ModificarVuelo
@codigo varchar(10),
@fechaHoraP datetime,
@fechaHoraL datetime,
@precioV float,
@estadoPartidaC varchar(4),
@estadoArriboC varchar(4)
as
Begin
	if not exists(select * from Vuelos where codigo = @codigo AND activoV = 1)
		return -1

	if not exists(select * from Estados where codigo = @estadoPartidaC AND activoE = 1)
		return -2

	if not exists(select * from Estados where codigo = @estadoArriboC AND activoE = 1)
		return -3

	UPDATE Vuelos SET fechaHoraP = @fechaHoraP, fechaHoraL = @fechaHoraL, precioV = @precioV, estadoPartidaC = @estadoPartidaC, estadoArriboC = @estadoArriboC
	 where codigo = @codigo
		if @@ERROR <> 0
			return -4

	return 1
End
go

CREATE PROCEDURE BuscarTodosVuelos
@codigo varchar(10)
as
Begin
	Select * from Vuelos
	Where codigo = @codigo
End
go

CREATE PROCEDURE BuscarVuelos
@codigo varchar(10)
as
Begin
	Select * from Vuelos
	Where codigo = @codigo AND activoV = 1
End
go

CREATE PROCEDURE ListarVuelos
as
Begin
	Select * from Vuelos where activoV = 1
End
go

-- Hospedaje --
CREATE PROCEDURE AltaHospedaje
@codigoInterno varchar(10),
@nombre varchar(30),
@calle varchar(30),
@localidad varchar(30),
@precioH float,
@tipoH varchar(13),
@estadoCodigo varchar(4)
as
Begin
	if exists(select * from Hospedajes where codigoInterno = @codigoInterno AND activoH = 1)
		return -1

	if not exists(select * from Estados where codigo = @estadoCodigo AND activoE = 1)
		return -2

	if exists(select * from Hospedajes where codigoInterno = @codigoInterno AND activoH = 0)
		Update Hospedajes SET nombre = @nombre, calle = @calle, localidad = @localidad, precioH = @precioH, tipoH = @tipoH, estadoCodigo = @estadoCodigo, activoH = 1
		where codigoInterno = @codigoInterno
			if @@ERROR <> 0
				return -4

	INSERT INTO Hospedajes (codigoInterno, nombre, calle, localidad, precioH, tipoH, estadoCodigo) 
	VALUES (@codigoInterno, @nombre, @calle, @localidad, @precioH, @tipoH, @estadoCodigo)
		if @@ERROR <> 0
			return -5

	return 1
End
go

CREATE PROCEDURE BajaHospedaje
@codigo varchar(10)
as
Begin
	if (not exists(Select * from Hospedajes where codigoInterno = @codigo))
		return -1

	-- baja logica si hay dependencias
	if (exists(Select * from Incluyen where codigoH = @codigo))
		Begin
			Update Vuelos Set activoV = 0 where codigo = @codigo
			return 1
		End
	-- baja fisica si no hay dependencias
	else
		Begin
			Delete Hospedajes where codigoInterno = @codigo
			if (@@ERROR <> 0)
				return -2
			else
				return 1
		End
End
go

CREATE PROCEDURE ModificarHospedaje
@codigoInterno varchar(10),
@nombre varchar(30),
@calle varchar(30),
@localidad varchar(30),
@precioH float,
@tipoH varchar(13),
@estadoCodigo varchar(4)
as
Begin
	if not exists(select * from Hospedajes where codigoInterno = @codigoInterno AND activoH = 1)
		return -1

	if not exists(select * from Estados where codigo = @estadoCodigo AND activoE = 1)
		return -2

	UPDATE Hospedajes SET nombre = @nombre, calle = @calle, localidad = @localidad, precioH = @precioH, tipoH = @tipoH,
	estadoCodigo = @estadoCodigo where codigoInterno = @codigoInterno
		if @@ERROR <> 0
			return -3

	return 1
End
go

CREATE PROCEDURE BuscarHospedaje
@codigo varchar(10)
as
Begin
	Select * from Hospedajes	
	Where codigoInterno = @codigo AND activoH = 1
End
go

CREATE PROCEDURE BuscarTodosHospedajes
@codigo varchar(10)
as
Begin
	Select * from Hospedajes	
	Where codigoInterno = @codigo
End
go

CREATE PROCEDURE ListarHospedajes
as
Begin
	Select *
	from Hospedajes where activoH = 1
	order by nombre
End
go

-- PaquetesViajes --
CREATE PROCEDURE AltaPaquetesViajes
@titulo varchar(25),
@descripcion varchar(MAX),
@cantidadDiasP int,
@precioIndividual float,
@precioDosP float,
@precioTresP float,
@empleadoU varchar(15),
@vueloIC varchar(10),
@vueloVC varchar(10),
@estadoPVC varchar(4)
as
Begin
	if not exists(select * from Empleados where usuario = @empleadoU)
		return - 1

	if not exists (select * from Vuelos where codigo = @vueloIC AND activoV = 1)
		return -2

	if not exists(select * from Vuelos where codigo = @vueloVC AND activoV = 1)
		return -3

	if not exists(select * from Estados where codigo = @estadoPVC AND activoE = 1)
		return - 4

	INSERT INTO PaquetesViajes (titulo, descripcion, cantidadDiasP, precioIndividual, precioDosP, precioTresP, empleadoU, vueloIC, vueloVC, estadoPVC)
	VALUES (@titulo, @descripcion, @cantidadDiasP, @precioIndividual, @precioDosP, @precioTresP, @empleadoU, @vueloIC, @vueloVC, @estadoPVC)
		if @@ERROR <> 0
			return -5

	return Scope_Identity()
End
go

CREATE PROCEDURE BuscarPaqueteViaje
@codigo int
as
Begin
	Select * from PaquetesViajes where codigo = @codigo
End
go

CREATE PROCEDURE AltaIncluyen
@codigoH varchar(10),
@codigoPV int,
@cantNoches int
as
Begin
	if not exists(select * from Hospedajes where codigoInterno = @codigoH AND activoH = 1)
		return -1

	if not exists(select * from PaquetesViajes where codigo = @codigoPV)
		return -2

	if exists(select * from Incluyen where codigoH = @codigoH AND codigoPV = @codigoPV)
		return -3

	INSERT INTO Incluyen (codigoH, codigoPV, cantNoches) VALUES (@codigoH, @codigoPV, @cantNoches)
		if @@ERROR <> 0
			return -4

	return 1
End
go

CREATE PROCEDURE ListarPaquetesViajesXHospedajes
@codigoH varchar(10)
as
Begin
	Select P.*
	from PaquetesViajes P inner join Incluyen I on P.codigo = I.codigoPV
	where I.codigoH = @codigoH
End
go

CREATE PROCEDURE ListarPaquetesViajes
as
Begin
	Select * from PaquetesViajes
End
go

CREATE PROCEDURE ListarIncluyenDePV
@codigoPV int
as
Begin
	Select * from Incluyen where codigoPV = @codigoPV
End
go
------------------------------------------------------------------------------------------
-- =========================================
-- BIOS TRAVEL - DATOS DE PRUEBA COMPLETOS
-- =========================================

-- EMPLEADOS
EXEC NuevoUsuario 'emp01','Abc1!','Juan Perez';
EXEC NuevoUsuario 'emp02','Def2@','Maria Gomez';
EXEC NuevoUsuario 'emp03','Ghi3#','Carlos Lopez';
EXEC NuevoUsuario 'emp04','Jkl4$','Ana Rodriguez';
EXEC NuevoUsuario 'emp05','Mno5%','Luis Fernandez';
EXEC NuevoUsuario 'emp06','Pqr6&','Laura Martinez';
EXEC NuevoUsuario 'emp07','Stu7*','Diego Suarez';
EXEC NuevoUsuario 'emp08','Vwx8(','Sofia Romero';
EXEC NuevoUsuario 'emp09','Yza9)','Martin Acosta';
EXEC NuevoUsuario 'emp10','Bcd0!','Valentina Nunez';
EXEC NuevoUsuario 'emp11','Efg1@','Pablo Rios';
EXEC NuevoUsuario 'emp12','Hij2#','Camila Torres';
EXEC NuevoUsuario 'emp13','Klm3$','Nicolas Vega';
EXEC NuevoUsuario 'emp14','Nop4%','Florencia Silva';
EXEC NuevoUsuario 'emp15','Qrs5&','Andres Morales';

-- ESTADOS
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AAAA','Estado 1','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('ABAA','Estado 2','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('ACAA','Estado 3','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('ADAA','Estado 4','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AEAA','Estado 5','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AFAA','Estado 6','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AGAA','Estado 7','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AHAA','Estado 8','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AIAA','Estado 9','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AJAA','Estado 10','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AKAA','Estado 11','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('ALAA','Estado 12','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AMAA','Estado 13','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('ANAA','Estado 14','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AOAA','Estado 15','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('APAA','Estado 16','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AQAA','Estado 17','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('ARAA','Estado 18','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('ASAA','Estado 19','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('ATAA','Estado 20','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AUAA','Estado 21','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AVAA','Estado 22','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AWAA','Estado 23','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AXAA','Estado 24','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AYAA','Estado 25','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('AZAA','Estado 26','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BAAA','Estado 27','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BBAA','Estado 28','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BCAA','Estado 29','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BDAA','Estado 30','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BEAA','Estado 31','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BFAA','Estado 32','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BGAA','Estado 33','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BHAA','Estado 34','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BIAA','Estado 35','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BJAA','Estado 36','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BKAA','Estado 37','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BLAA','Estado 38','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BMAA','Estado 39','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BNAA','Estado 40','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BOAA','Estado 41','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BPAA','Estado 42','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BQAA','Estado 43','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BRAA','Estado 44','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BSAA','Estado 45','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BTAA','Estado 46','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BUAA','Estado 47','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BVAA','Estado 48','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BWAA','Estado 49','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BXAA','Estado 50','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BYAA','Estado 51','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('BZAA','Estado 52','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CAAA','Estado 53','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CBAA','Estado 54','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CCAA','Estado 55','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CDAA','Estado 56','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CEAA','Estado 57','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CFAA','Estado 58','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CGAA','Estado 59','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CHAA','Estado 60','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CIAA','Estado 61','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CJAA','Estado 62','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CKAA','Estado 63','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CLAA','Estado 64','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CMAA','Estado 65','Uruguay');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CNAA','Estado 66','España');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('COAA','Estado 67','Argentina');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CPAA','Estado 68','Brasil');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CQAA','Estado 69','Chile');
INSERT INTO Estados (codigo,nombre,pais) VALUES ('CRAA','Estado 70','Uruguay');

-- VUELOS
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00001',DATEADD(DAY,91,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,91,GETDATE())),121.7,'AAAA','AIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00002',DATEADD(DAY,92,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,92,GETDATE())),123.4,'ABAA','AJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00003',DATEADD(DAY,93,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,93,GETDATE())),125.1,'ACAA','AKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00004',DATEADD(DAY,94,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,94,GETDATE())),126.8,'ADAA','ALAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00005',DATEADD(DAY,95,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,95,GETDATE())),128.5,'AEAA','AMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00006',DATEADD(DAY,96,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,96,GETDATE())),130.2,'AFAA','ANAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00007',DATEADD(DAY,97,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,97,GETDATE())),131.9,'AGAA','AOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00008',DATEADD(DAY,98,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,98,GETDATE())),133.6,'AHAA','APAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00009',DATEADD(DAY,99,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,99,GETDATE())),135.3,'AIAA','AQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00010',DATEADD(DAY,100,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,100,GETDATE())),137.0,'AJAA','ARAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00011',DATEADD(DAY,101,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,101,GETDATE())),138.7,'AKAA','ASAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00012',DATEADD(DAY,102,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,102,GETDATE())),140.4,'ALAA','ATAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00013',DATEADD(DAY,103,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,103,GETDATE())),142.1,'AMAA','AUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00014',DATEADD(DAY,104,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,104,GETDATE())),143.8,'ANAA','AVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00015',DATEADD(DAY,105,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,105,GETDATE())),145.5,'AOAA','AWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00016',DATEADD(DAY,106,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,106,GETDATE())),147.2,'APAA','AXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00017',DATEADD(DAY,107,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,107,GETDATE())),148.9,'AQAA','AYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00018',DATEADD(DAY,108,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,108,GETDATE())),150.6,'ARAA','AZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00019',DATEADD(DAY,109,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,109,GETDATE())),152.3,'ASAA','BAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00020',DATEADD(DAY,110,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,110,GETDATE())),154.0,'ATAA','BBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00021',DATEADD(DAY,111,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,111,GETDATE())),155.7,'AUAA','BCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00022',DATEADD(DAY,112,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,112,GETDATE())),157.4,'AVAA','BDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00023',DATEADD(DAY,113,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,113,GETDATE())),159.1,'AWAA','BEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00024',DATEADD(DAY,114,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,114,GETDATE())),160.8,'AXAA','BFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00025',DATEADD(DAY,115,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,115,GETDATE())),162.5,'AYAA','BGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00026',DATEADD(DAY,116,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,116,GETDATE())),164.2,'AZAA','BHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00027',DATEADD(DAY,117,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,117,GETDATE())),165.9,'BAAA','BIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00028',DATEADD(DAY,118,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,118,GETDATE())),167.6,'BBAA','BJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00029',DATEADD(DAY,119,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,119,GETDATE())),169.3,'BCAA','BKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00030',DATEADD(DAY,120,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,120,GETDATE())),171.0,'BDAA','BLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00031',DATEADD(DAY,121,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,121,GETDATE())),172.7,'BEAA','BMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00032',DATEADD(DAY,122,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,122,GETDATE())),174.4,'BFAA','BNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00033',DATEADD(DAY,123,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,123,GETDATE())),176.1,'BGAA','BOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00034',DATEADD(DAY,124,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,124,GETDATE())),177.8,'BHAA','BPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00035',DATEADD(DAY,125,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,125,GETDATE())),179.5,'BIAA','BQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00036',DATEADD(DAY,126,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,126,GETDATE())),181.2,'BJAA','BRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00037',DATEADD(DAY,127,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,127,GETDATE())),182.9,'BKAA','BSAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00038',DATEADD(DAY,128,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,128,GETDATE())),184.6,'BLAA','BTAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00039',DATEADD(DAY,129,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,129,GETDATE())),186.3,'BMAA','BUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00040',DATEADD(DAY,130,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,130,GETDATE())),188.0,'BNAA','BVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00041',DATEADD(DAY,131,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,131,GETDATE())),189.7,'BOAA','BWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00042',DATEADD(DAY,132,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,132,GETDATE())),191.39999999999998,'BPAA','BXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00043',DATEADD(DAY,133,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,133,GETDATE())),193.1,'BQAA','BYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00044',DATEADD(DAY,134,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,134,GETDATE())),194.8,'BRAA','BZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00045',DATEADD(DAY,135,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,135,GETDATE())),196.5,'BSAA','CAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00046',DATEADD(DAY,136,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,136,GETDATE())),198.2,'BTAA','CBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00047',DATEADD(DAY,137,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,137,GETDATE())),199.89999999999998,'BUAA','CCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00048',DATEADD(DAY,138,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,138,GETDATE())),201.6,'BVAA','CDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00049',DATEADD(DAY,139,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,139,GETDATE())),203.3,'BWAA','CEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00050',DATEADD(DAY,140,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,140,GETDATE())),205.0,'BXAA','CFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00051',DATEADD(DAY,141,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,141,GETDATE())),206.7,'BYAA','CGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00052',DATEADD(DAY,142,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,142,GETDATE())),208.39999999999998,'BZAA','CHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00053',DATEADD(DAY,143,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,143,GETDATE())),210.1,'CAAA','CIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00054',DATEADD(DAY,144,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,144,GETDATE())),211.8,'CBAA','CJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00055',DATEADD(DAY,145,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,145,GETDATE())),213.5,'CCAA','CKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00056',DATEADD(DAY,146,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,146,GETDATE())),215.2,'CDAA','CLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00057',DATEADD(DAY,147,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,147,GETDATE())),216.89999999999998,'CEAA','CMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00058',DATEADD(DAY,148,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,148,GETDATE())),218.6,'CFAA','CNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00059',DATEADD(DAY,149,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,149,GETDATE())),220.3,'CGAA','COAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00060',DATEADD(DAY,150,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,150,GETDATE())),222.0,'CHAA','CPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00061',DATEADD(DAY,151,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,151,GETDATE())),223.7,'CIAA','CQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00062',DATEADD(DAY,152,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,152,GETDATE())),225.39999999999998,'CJAA','CRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00063',DATEADD(DAY,153,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,153,GETDATE())),227.1,'CKAA','AAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00064',DATEADD(DAY,154,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,154,GETDATE())),228.8,'CLAA','ABAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00065',DATEADD(DAY,155,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,155,GETDATE())),230.5,'CMAA','ACAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00066',DATEADD(DAY,156,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,156,GETDATE())),232.2,'CNAA','ADAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00067',DATEADD(DAY,157,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,157,GETDATE())),233.89999999999998,'COAA','AEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00068',DATEADD(DAY,158,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,158,GETDATE())),235.6,'CPAA','AFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00069',DATEADD(DAY,159,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,159,GETDATE())),237.3,'CQAA','AGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00070',DATEADD(DAY,160,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,160,GETDATE())),239.0,'CRAA','AHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00071',DATEADD(DAY,161,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,161,GETDATE())),240.7,'AAAA','AIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00072',DATEADD(DAY,162,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,162,GETDATE())),242.39999999999998,'ABAA','AJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00073',DATEADD(DAY,163,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,163,GETDATE())),244.1,'ACAA','AKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00074',DATEADD(DAY,164,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,164,GETDATE())),245.8,'ADAA','ALAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00075',DATEADD(DAY,165,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,165,GETDATE())),247.5,'AEAA','AMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00076',DATEADD(DAY,166,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,166,GETDATE())),249.2,'AFAA','ANAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00077',DATEADD(DAY,167,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,167,GETDATE())),250.9,'AGAA','AOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00078',DATEADD(DAY,168,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,168,GETDATE())),252.6,'AHAA','APAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00079',DATEADD(DAY,169,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,169,GETDATE())),254.29999999999998,'AIAA','AQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00080',DATEADD(DAY,170,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,170,GETDATE())),256.0,'AJAA','ARAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00081',DATEADD(DAY,171,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,171,GETDATE())),257.7,'AKAA','ASAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00082',DATEADD(DAY,172,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,172,GETDATE())),259.4,'ALAA','ATAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00083',DATEADD(DAY,173,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,173,GETDATE())),261.1,'AMAA','AUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00084',DATEADD(DAY,174,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,174,GETDATE())),262.79999999999995,'ANAA','AVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00085',DATEADD(DAY,175,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,175,GETDATE())),264.5,'AOAA','AWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00086',DATEADD(DAY,176,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,176,GETDATE())),266.2,'APAA','AXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00087',DATEADD(DAY,177,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,177,GETDATE())),267.9,'AQAA','AYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00088',DATEADD(DAY,178,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,178,GETDATE())),269.6,'ARAA','AZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00089',DATEADD(DAY,179,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,179,GETDATE())),271.29999999999995,'ASAA','BAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00090',DATEADD(DAY,180,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,180,GETDATE())),273.0,'ATAA','BBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00091',DATEADD(DAY,181,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,181,GETDATE())),274.7,'AUAA','BCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00092',DATEADD(DAY,182,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,182,GETDATE())),276.4,'AVAA','BDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00093',DATEADD(DAY,183,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,183,GETDATE())),278.1,'AWAA','BEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00094',DATEADD(DAY,184,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,184,GETDATE())),279.79999999999995,'AXAA','BFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00095',DATEADD(DAY,185,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,185,GETDATE())),281.5,'AYAA','BGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00096',DATEADD(DAY,186,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,186,GETDATE())),283.2,'AZAA','BHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00097',DATEADD(DAY,187,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,187,GETDATE())),284.9,'BAAA','BIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00098',DATEADD(DAY,188,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,188,GETDATE())),286.6,'BBAA','BJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00099',DATEADD(DAY,189,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,189,GETDATE())),288.29999999999995,'BCAA','BKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00100',DATEADD(DAY,190,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,190,GETDATE())),290.0,'BDAA','BLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00101',DATEADD(DAY,191,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,191,GETDATE())),291.7,'BEAA','BMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00102',DATEADD(DAY,192,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,192,GETDATE())),293.4,'BFAA','BNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00103',DATEADD(DAY,193,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,193,GETDATE())),295.1,'BGAA','BOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00104',DATEADD(DAY,194,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,194,GETDATE())),296.79999999999995,'BHAA','BPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00105',DATEADD(DAY,195,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,195,GETDATE())),298.5,'BIAA','BQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00106',DATEADD(DAY,196,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,196,GETDATE())),300.2,'BJAA','BRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00107',DATEADD(DAY,197,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,197,GETDATE())),301.9,'BKAA','BSAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00108',DATEADD(DAY,198,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,198,GETDATE())),303.6,'BLAA','BTAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00109',DATEADD(DAY,199,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,199,GETDATE())),305.29999999999995,'BMAA','BUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00110',DATEADD(DAY,200,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,200,GETDATE())),307.0,'BNAA','BVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00111',DATEADD(DAY,201,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,201,GETDATE())),308.7,'BOAA','BWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00112',DATEADD(DAY,202,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,202,GETDATE())),310.4,'BPAA','BXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00113',DATEADD(DAY,203,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,203,GETDATE())),312.1,'BQAA','BYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00114',DATEADD(DAY,204,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,204,GETDATE())),313.79999999999995,'BRAA','BZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00115',DATEADD(DAY,205,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,205,GETDATE())),315.5,'BSAA','CAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00116',DATEADD(DAY,206,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,206,GETDATE())),317.2,'BTAA','CBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00117',DATEADD(DAY,207,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,207,GETDATE())),318.9,'BUAA','CCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00118',DATEADD(DAY,208,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,208,GETDATE())),320.6,'BVAA','CDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00119',DATEADD(DAY,209,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,209,GETDATE())),322.29999999999995,'BWAA','CEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00120',DATEADD(DAY,210,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,210,GETDATE())),324.0,'BXAA','CFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00121',DATEADD(DAY,211,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,211,GETDATE())),325.7,'BYAA','CGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00122',DATEADD(DAY,212,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,212,GETDATE())),327.4,'BZAA','CHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00123',DATEADD(DAY,213,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,213,GETDATE())),329.1,'CAAA','CIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00124',DATEADD(DAY,214,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,214,GETDATE())),330.79999999999995,'CBAA','CJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00125',DATEADD(DAY,215,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,215,GETDATE())),332.5,'CCAA','CKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00126',DATEADD(DAY,216,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,216,GETDATE())),334.2,'CDAA','CLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00127',DATEADD(DAY,217,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,217,GETDATE())),335.9,'CEAA','CMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00128',DATEADD(DAY,218,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,218,GETDATE())),337.6,'CFAA','CNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00129',DATEADD(DAY,219,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,219,GETDATE())),339.29999999999995,'CGAA','COAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00130',DATEADD(DAY,220,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,220,GETDATE())),341.0,'CHAA','CPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00131',DATEADD(DAY,221,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,221,GETDATE())),342.7,'CIAA','CQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00132',DATEADD(DAY,222,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,222,GETDATE())),344.4,'CJAA','CRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00133',DATEADD(DAY,223,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,223,GETDATE())),346.1,'CKAA','AAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00134',DATEADD(DAY,224,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,224,GETDATE())),347.79999999999995,'CLAA','ABAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00135',DATEADD(DAY,225,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,225,GETDATE())),349.5,'CMAA','ACAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00136',DATEADD(DAY,226,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,226,GETDATE())),351.2,'CNAA','ADAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00137',DATEADD(DAY,227,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,227,GETDATE())),352.9,'COAA','AEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00138',DATEADD(DAY,228,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,228,GETDATE())),354.6,'CPAA','AFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00139',DATEADD(DAY,229,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,229,GETDATE())),356.29999999999995,'CQAA','AGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00140',DATEADD(DAY,230,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,230,GETDATE())),358.0,'CRAA','AHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00141',DATEADD(DAY,231,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,231,GETDATE())),359.7,'AAAA','AIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00142',DATEADD(DAY,232,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,232,GETDATE())),361.4,'ABAA','AJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00143',DATEADD(DAY,233,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,233,GETDATE())),363.1,'ACAA','AKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00144',DATEADD(DAY,234,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,234,GETDATE())),364.79999999999995,'ADAA','ALAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00145',DATEADD(DAY,235,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,235,GETDATE())),366.5,'AEAA','AMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00146',DATEADD(DAY,236,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,236,GETDATE())),368.2,'AFAA','ANAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00147',DATEADD(DAY,237,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,237,GETDATE())),369.9,'AGAA','AOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00148',DATEADD(DAY,238,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,238,GETDATE())),371.6,'AHAA','APAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00149',DATEADD(DAY,239,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,239,GETDATE())),373.29999999999995,'AIAA','AQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00150',DATEADD(DAY,240,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,240,GETDATE())),375.0,'AJAA','ARAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00151',DATEADD(DAY,241,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,241,GETDATE())),376.7,'AKAA','ASAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00152',DATEADD(DAY,242,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,242,GETDATE())),378.4,'ALAA','ATAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00153',DATEADD(DAY,243,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,243,GETDATE())),380.09999999999997,'AMAA','AUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00154',DATEADD(DAY,244,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,244,GETDATE())),381.8,'ANAA','AVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00155',DATEADD(DAY,245,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,245,GETDATE())),383.5,'AOAA','AWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00156',DATEADD(DAY,246,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,246,GETDATE())),385.2,'APAA','AXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00157',DATEADD(DAY,247,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,247,GETDATE())),386.9,'AQAA','AYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00158',DATEADD(DAY,248,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,248,GETDATE())),388.59999999999997,'ARAA','AZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00159',DATEADD(DAY,249,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,249,GETDATE())),390.3,'ASAA','BAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00160',DATEADD(DAY,250,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,250,GETDATE())),392.0,'ATAA','BBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00161',DATEADD(DAY,251,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,251,GETDATE())),393.7,'AUAA','BCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00162',DATEADD(DAY,252,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,252,GETDATE())),395.4,'AVAA','BDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00163',DATEADD(DAY,253,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,253,GETDATE())),397.09999999999997,'AWAA','BEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00164',DATEADD(DAY,254,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,254,GETDATE())),398.8,'AXAA','BFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00165',DATEADD(DAY,255,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,255,GETDATE())),400.5,'AYAA','BGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00166',DATEADD(DAY,256,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,256,GETDATE())),402.2,'AZAA','BHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00167',DATEADD(DAY,257,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,257,GETDATE())),403.9,'BAAA','BIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00168',DATEADD(DAY,258,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,258,GETDATE())),405.59999999999997,'BBAA','BJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00169',DATEADD(DAY,259,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,259,GETDATE())),407.3,'BCAA','BKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00170',DATEADD(DAY,260,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,260,GETDATE())),409.0,'BDAA','BLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00171',DATEADD(DAY,261,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,261,GETDATE())),410.7,'BEAA','BMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00172',DATEADD(DAY,262,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,262,GETDATE())),412.4,'BFAA','BNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00173',DATEADD(DAY,263,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,263,GETDATE())),414.09999999999997,'BGAA','BOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00174',DATEADD(DAY,264,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,264,GETDATE())),415.8,'BHAA','BPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00175',DATEADD(DAY,265,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,265,GETDATE())),417.5,'BIAA','BQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00176',DATEADD(DAY,266,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,266,GETDATE())),419.2,'BJAA','BRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00177',DATEADD(DAY,267,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,267,GETDATE())),420.9,'BKAA','BSAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00178',DATEADD(DAY,268,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,268,GETDATE())),422.59999999999997,'BLAA','BTAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00179',DATEADD(DAY,269,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,269,GETDATE())),424.3,'BMAA','BUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00180',DATEADD(DAY,270,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,270,GETDATE())),426.0,'BNAA','BVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00181',DATEADD(DAY,271,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,271,GETDATE())),427.7,'BOAA','BWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00182',DATEADD(DAY,272,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,272,GETDATE())),429.4,'BPAA','BXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00183',DATEADD(DAY,273,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,273,GETDATE())),431.09999999999997,'BQAA','BYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00184',DATEADD(DAY,274,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,274,GETDATE())),432.8,'BRAA','BZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00185',DATEADD(DAY,275,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,275,GETDATE())),434.5,'BSAA','CAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00186',DATEADD(DAY,276,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,276,GETDATE())),436.2,'BTAA','CBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00187',DATEADD(DAY,277,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,277,GETDATE())),437.9,'BUAA','CCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00188',DATEADD(DAY,278,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,278,GETDATE())),439.59999999999997,'BVAA','CDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00189',DATEADD(DAY,279,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,279,GETDATE())),441.3,'BWAA','CEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00190',DATEADD(DAY,280,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,280,GETDATE())),443.0,'BXAA','CFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00191',DATEADD(DAY,281,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,281,GETDATE())),444.7,'BYAA','CGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00192',DATEADD(DAY,282,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,282,GETDATE())),446.4,'BZAA','CHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00193',DATEADD(DAY,283,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,283,GETDATE())),448.09999999999997,'CAAA','CIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00194',DATEADD(DAY,284,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,284,GETDATE())),449.8,'CBAA','CJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00195',DATEADD(DAY,285,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,285,GETDATE())),451.5,'CCAA','CKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00196',DATEADD(DAY,286,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,286,GETDATE())),453.2,'CDAA','CLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00197',DATEADD(DAY,287,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,287,GETDATE())),454.9,'CEAA','CMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00198',DATEADD(DAY,288,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,288,GETDATE())),456.59999999999997,'CFAA','CNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00199',DATEADD(DAY,289,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,289,GETDATE())),458.3,'CGAA','COAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00200',DATEADD(DAY,290,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,290,GETDATE())),460.0,'CHAA','CPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00201',DATEADD(DAY,291,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,291,GETDATE())),461.7,'CIAA','CQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00202',DATEADD(DAY,292,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,292,GETDATE())),463.4,'CJAA','CRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00203',DATEADD(DAY,293,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,293,GETDATE())),465.09999999999997,'CKAA','AAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00204',DATEADD(DAY,294,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,294,GETDATE())),466.8,'CLAA','ABAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00205',DATEADD(DAY,295,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,295,GETDATE())),468.5,'CMAA','ACAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00206',DATEADD(DAY,296,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,296,GETDATE())),470.2,'CNAA','ADAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00207',DATEADD(DAY,297,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,297,GETDATE())),471.9,'COAA','AEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00208',DATEADD(DAY,298,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,298,GETDATE())),473.59999999999997,'CPAA','AFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00209',DATEADD(DAY,299,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,299,GETDATE())),475.3,'CQAA','AGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00210',DATEADD(DAY,300,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,300,GETDATE())),477.0,'CRAA','AHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00211',DATEADD(DAY,301,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,301,GETDATE())),478.7,'AAAA','AIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00212',DATEADD(DAY,302,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,302,GETDATE())),480.4,'ABAA','AJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00213',DATEADD(DAY,303,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,303,GETDATE())),482.09999999999997,'ACAA','AKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00214',DATEADD(DAY,304,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,304,GETDATE())),483.8,'ADAA','ALAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00215',DATEADD(DAY,305,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,305,GETDATE())),485.5,'AEAA','AMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00216',DATEADD(DAY,306,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,306,GETDATE())),487.2,'AFAA','ANAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00217',DATEADD(DAY,307,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,307,GETDATE())),488.9,'AGAA','AOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00218',DATEADD(DAY,308,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,308,GETDATE())),490.59999999999997,'AHAA','APAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00219',DATEADD(DAY,309,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,309,GETDATE())),492.3,'AIAA','AQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00220',DATEADD(DAY,310,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,310,GETDATE())),494.0,'AJAA','ARAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00221',DATEADD(DAY,311,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,311,GETDATE())),495.7,'AKAA','ASAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00222',DATEADD(DAY,312,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,312,GETDATE())),497.4,'ALAA','ATAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00223',DATEADD(DAY,313,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,313,GETDATE())),499.09999999999997,'AMAA','AUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00224',DATEADD(DAY,314,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,314,GETDATE())),500.8,'ANAA','AVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00225',DATEADD(DAY,315,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,315,GETDATE())),502.5,'AOAA','AWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00226',DATEADD(DAY,316,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,316,GETDATE())),504.2,'APAA','AXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00227',DATEADD(DAY,317,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,317,GETDATE())),505.9,'AQAA','AYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00228',DATEADD(DAY,318,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,318,GETDATE())),507.59999999999997,'ARAA','AZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00229',DATEADD(DAY,319,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,319,GETDATE())),509.3,'ASAA','BAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00230',DATEADD(DAY,320,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,320,GETDATE())),511.0,'ATAA','BBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00231',DATEADD(DAY,321,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,321,GETDATE())),512.7,'AUAA','BCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00232',DATEADD(DAY,322,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,322,GETDATE())),514.4,'AVAA','BDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00233',DATEADD(DAY,323,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,323,GETDATE())),516.0999999999999,'AWAA','BEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00234',DATEADD(DAY,324,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,324,GETDATE())),517.8,'AXAA','BFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00235',DATEADD(DAY,325,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,325,GETDATE())),519.5,'AYAA','BGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00236',DATEADD(DAY,326,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,326,GETDATE())),521.2,'AZAA','BHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00237',DATEADD(DAY,327,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,327,GETDATE())),522.9,'BAAA','BIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00238',DATEADD(DAY,328,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,328,GETDATE())),524.5999999999999,'BBAA','BJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00239',DATEADD(DAY,329,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,329,GETDATE())),526.3,'BCAA','BKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00240',DATEADD(DAY,330,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,330,GETDATE())),528.0,'BDAA','BLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00241',DATEADD(DAY,331,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,331,GETDATE())),529.7,'BEAA','BMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00242',DATEADD(DAY,332,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,332,GETDATE())),531.4,'BFAA','BNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00243',DATEADD(DAY,333,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,333,GETDATE())),533.0999999999999,'BGAA','BOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00244',DATEADD(DAY,334,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,334,GETDATE())),534.8,'BHAA','BPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00245',DATEADD(DAY,335,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,335,GETDATE())),536.5,'BIAA','BQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00246',DATEADD(DAY,336,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,336,GETDATE())),538.2,'BJAA','BRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00247',DATEADD(DAY,337,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,337,GETDATE())),539.9,'BKAA','BSAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00248',DATEADD(DAY,338,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,338,GETDATE())),541.5999999999999,'BLAA','BTAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00249',DATEADD(DAY,339,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,339,GETDATE())),543.3,'BMAA','BUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00250',DATEADD(DAY,340,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,340,GETDATE())),545.0,'BNAA','BVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00251',DATEADD(DAY,341,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,341,GETDATE())),546.7,'BOAA','BWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00252',DATEADD(DAY,342,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,342,GETDATE())),548.4,'BPAA','BXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00253',DATEADD(DAY,343,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,343,GETDATE())),550.0999999999999,'BQAA','BYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00254',DATEADD(DAY,344,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,344,GETDATE())),551.8,'BRAA','BZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00255',DATEADD(DAY,345,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,345,GETDATE())),553.5,'BSAA','CAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00256',DATEADD(DAY,346,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,346,GETDATE())),555.2,'BTAA','CBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00257',DATEADD(DAY,347,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,347,GETDATE())),556.9,'BUAA','CCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00258',DATEADD(DAY,348,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,348,GETDATE())),558.5999999999999,'BVAA','CDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00259',DATEADD(DAY,349,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,349,GETDATE())),560.3,'BWAA','CEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00260',DATEADD(DAY,350,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,350,GETDATE())),562.0,'BXAA','CFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00261',DATEADD(DAY,351,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,351,GETDATE())),563.7,'BYAA','CGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00262',DATEADD(DAY,352,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,352,GETDATE())),565.4,'BZAA','CHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00263',DATEADD(DAY,353,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,353,GETDATE())),567.0999999999999,'CAAA','CIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00264',DATEADD(DAY,354,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,354,GETDATE())),568.8,'CBAA','CJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00265',DATEADD(DAY,355,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,355,GETDATE())),570.5,'CCAA','CKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00266',DATEADD(DAY,356,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,356,GETDATE())),572.2,'CDAA','CLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00267',DATEADD(DAY,357,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,357,GETDATE())),573.9,'CEAA','CMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00268',DATEADD(DAY,358,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,358,GETDATE())),575.5999999999999,'CFAA','CNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00269',DATEADD(DAY,359,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,359,GETDATE())),577.3,'CGAA','COAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00270',DATEADD(DAY,360,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,360,GETDATE())),579.0,'CHAA','CPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00271',DATEADD(DAY,361,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,361,GETDATE())),580.7,'CIAA','CQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00272',DATEADD(DAY,362,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,362,GETDATE())),582.4,'CJAA','CRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00273',DATEADD(DAY,363,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,363,GETDATE())),584.0999999999999,'CKAA','AAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00274',DATEADD(DAY,364,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,364,GETDATE())),585.8,'CLAA','ABAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00275',DATEADD(DAY,365,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,365,GETDATE())),587.5,'CMAA','ACAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00276',DATEADD(DAY,366,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,366,GETDATE())),589.2,'CNAA','ADAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00277',DATEADD(DAY,367,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,367,GETDATE())),590.9,'COAA','AEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00278',DATEADD(DAY,368,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,368,GETDATE())),592.5999999999999,'CPAA','AFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00279',DATEADD(DAY,369,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,369,GETDATE())),594.3,'CQAA','AGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00280',DATEADD(DAY,370,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,370,GETDATE())),596.0,'CRAA','AHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00281',DATEADD(DAY,371,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,371,GETDATE())),597.7,'AAAA','AIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00282',DATEADD(DAY,372,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,372,GETDATE())),599.4,'ABAA','AJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00283',DATEADD(DAY,373,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,373,GETDATE())),601.0999999999999,'ACAA','AKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00284',DATEADD(DAY,374,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,374,GETDATE())),602.8,'ADAA','ALAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00285',DATEADD(DAY,375,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,375,GETDATE())),604.5,'AEAA','AMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00286',DATEADD(DAY,376,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,376,GETDATE())),606.2,'AFAA','ANAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00287',DATEADD(DAY,377,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,377,GETDATE())),607.9,'AGAA','AOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00288',DATEADD(DAY,378,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,378,GETDATE())),609.5999999999999,'AHAA','APAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00289',DATEADD(DAY,379,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,379,GETDATE())),611.3,'AIAA','AQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00290',DATEADD(DAY,380,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,380,GETDATE())),613.0,'AJAA','ARAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00291',DATEADD(DAY,381,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,381,GETDATE())),614.7,'AKAA','ASAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00292',DATEADD(DAY,382,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,382,GETDATE())),616.4,'ALAA','ATAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00293',DATEADD(DAY,383,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,383,GETDATE())),618.0999999999999,'AMAA','AUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00294',DATEADD(DAY,384,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,384,GETDATE())),619.8,'ANAA','AVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00295',DATEADD(DAY,385,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,385,GETDATE())),621.5,'AOAA','AWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00296',DATEADD(DAY,386,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,386,GETDATE())),623.2,'APAA','AXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00297',DATEADD(DAY,387,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,387,GETDATE())),624.9,'AQAA','AYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00298',DATEADD(DAY,388,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,388,GETDATE())),626.5999999999999,'ARAA','AZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00299',DATEADD(DAY,389,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,389,GETDATE())),628.3,'ASAA','BAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00300',DATEADD(DAY,390,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,390,GETDATE())),630.0,'ATAA','BBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00301',DATEADD(DAY,391,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,391,GETDATE())),631.7,'AUAA','BCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00302',DATEADD(DAY,392,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,392,GETDATE())),633.4,'AVAA','BDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00303',DATEADD(DAY,393,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,393,GETDATE())),635.1,'AWAA','BEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00304',DATEADD(DAY,394,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,394,GETDATE())),636.8,'AXAA','BFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00305',DATEADD(DAY,395,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,395,GETDATE())),638.5,'AYAA','BGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00306',DATEADD(DAY,396,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,396,GETDATE())),640.1999999999999,'AZAA','BHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00307',DATEADD(DAY,397,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,397,GETDATE())),641.9,'BAAA','BIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00308',DATEADD(DAY,398,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,398,GETDATE())),643.6,'BBAA','BJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00309',DATEADD(DAY,399,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,399,GETDATE())),645.3,'BCAA','BKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00310',DATEADD(DAY,400,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,400,GETDATE())),647.0,'BDAA','BLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00311',DATEADD(DAY,401,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,401,GETDATE())),648.6999999999999,'BEAA','BMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00312',DATEADD(DAY,402,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,402,GETDATE())),650.4,'BFAA','BNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00313',DATEADD(DAY,403,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,403,GETDATE())),652.1,'BGAA','BOAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00314',DATEADD(DAY,404,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,404,GETDATE())),653.8,'BHAA','BPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00315',DATEADD(DAY,405,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,405,GETDATE())),655.5,'BIAA','BQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00316',DATEADD(DAY,406,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,406,GETDATE())),657.1999999999999,'BJAA','BRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00317',DATEADD(DAY,407,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,407,GETDATE())),658.9,'BKAA','BSAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00318',DATEADD(DAY,408,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,408,GETDATE())),660.6,'BLAA','BTAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00319',DATEADD(DAY,409,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,409,GETDATE())),662.3,'BMAA','BUAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00320',DATEADD(DAY,410,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,410,GETDATE())),664.0,'BNAA','BVAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00321',DATEADD(DAY,411,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,411,GETDATE())),665.6999999999999,'BOAA','BWAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00322',DATEADD(DAY,412,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,412,GETDATE())),667.4,'BPAA','BXAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00323',DATEADD(DAY,413,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,413,GETDATE())),669.1,'BQAA','BYAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00324',DATEADD(DAY,414,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,414,GETDATE())),670.8,'BRAA','BZAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00325',DATEADD(DAY,415,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,415,GETDATE())),672.5,'BSAA','CAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00326',DATEADD(DAY,416,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,416,GETDATE())),674.1999999999999,'BTAA','CBAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00327',DATEADD(DAY,417,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,417,GETDATE())),675.9,'BUAA','CCAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00328',DATEADD(DAY,418,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,418,GETDATE())),677.6,'BVAA','CDAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00329',DATEADD(DAY,419,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,419,GETDATE())),679.3,'BWAA','CEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00330',DATEADD(DAY,420,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,420,GETDATE())),681.0,'BXAA','CFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00331',DATEADD(DAY,421,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,421,GETDATE())),682.6999999999999,'BYAA','CGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00332',DATEADD(DAY,422,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,422,GETDATE())),684.4,'BZAA','CHAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00333',DATEADD(DAY,423,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,423,GETDATE())),686.1,'CAAA','CIAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00334',DATEADD(DAY,424,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,424,GETDATE())),687.8,'CBAA','CJAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00335',DATEADD(DAY,425,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,425,GETDATE())),689.5,'CCAA','CKAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00336',DATEADD(DAY,426,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,426,GETDATE())),691.1999999999999,'CDAA','CLAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00337',DATEADD(DAY,427,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,427,GETDATE())),692.9,'CEAA','CMAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00338',DATEADD(DAY,428,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,428,GETDATE())),694.6,'CFAA','CNAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00339',DATEADD(DAY,429,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,429,GETDATE())),696.3,'CGAA','COAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00340',DATEADD(DAY,430,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,430,GETDATE())),698.0,'CHAA','CPAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00341',DATEADD(DAY,431,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,431,GETDATE())),699.6999999999999,'CIAA','CQAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00342',DATEADD(DAY,432,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,432,GETDATE())),701.4,'CJAA','CRAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00343',DATEADD(DAY,433,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,433,GETDATE())),703.1,'CKAA','AAAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00344',DATEADD(DAY,434,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,434,GETDATE())),704.8,'CLAA','ABAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00345',DATEADD(DAY,435,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,435,GETDATE())),706.5,'CMAA','ACAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00346',DATEADD(DAY,436,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,436,GETDATE())),708.1999999999999,'CNAA','ADAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00347',DATEADD(DAY,437,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,437,GETDATE())),709.9,'COAA','AEAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00348',DATEADD(DAY,438,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,438,GETDATE())),711.6,'CPAA','AFAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00349',DATEADD(DAY,439,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,439,GETDATE())),713.3,'CQAA','AGAA');
INSERT INTO Vuelos (codigo,fechaHoraP,fechaHoraL,precioV,estadoPartidaC,estadoArriboC) VALUES ('VUELO00350',DATEADD(DAY,440,GETDATE()),DATEADD(HOUR,5,DATEADD(DAY,440,GETDATE())),715.0,'CRAA','AHAA');

-- HOSPEDAJES
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAA','Hospedaje 1','Calle 1','Ciudad 1',70.0,'Hotel STD','AAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAB','Hospedaje 2','Calle 2','Ciudad 2',71.3,'Posada','ABAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAC','Hospedaje 3','Calle 3','Ciudad 3',72.6,'All Inclusive','ACAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAD','Hospedaje 4','Calle 4','Ciudad 4',73.9,'Hotel STD','ADAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAE','Hospedaje 5','Calle 5','Ciudad 5',75.2,'Posada','AEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAF','Hospedaje 6','Calle 6','Ciudad 6',76.5,'All Inclusive','AFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAG','Hospedaje 7','Calle 7','Ciudad 7',77.8,'Hotel STD','AGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAH','Hospedaje 8','Calle 8','Ciudad 8',79.1,'Posada','AHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAI','Hospedaje 9','Calle 9','Ciudad 9',80.4,'All Inclusive','AIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAJ','Hospedaje 10','Calle 10','Ciudad 10',81.7,'Hotel STD','AJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAK','Hospedaje 11','Calle 11','Ciudad 11',83.0,'Posada','AKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAL','Hospedaje 12','Calle 12','Ciudad 12',84.3,'All Inclusive','ALAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAM','Hospedaje 13','Calle 13','Ciudad 13',85.6,'Hotel STD','AMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAN','Hospedaje 14','Calle 14','Ciudad 14',86.9,'Posada','ANAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAO','Hospedaje 15','Calle 15','Ciudad 15',88.2,'All Inclusive','AOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAP','Hospedaje 16','Calle 16','Ciudad 16',89.5,'Hotel STD','APAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAQ','Hospedaje 17','Calle 17','Ciudad 17',90.8,'Posada','AQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAR','Hospedaje 18','Calle 18','Ciudad 18',92.1,'All Inclusive','ARAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAS','Hospedaje 19','Calle 19','Ciudad 19',93.4,'Hotel STD','ASAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAT','Hospedaje 20','Calle 20','Ciudad 20',94.7,'Posada','ATAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAU','Hospedaje 21','Calle 21','Ciudad 21',96.0,'All Inclusive','AUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAV','Hospedaje 22','Calle 22','Ciudad 22',97.3,'Hotel STD','AVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAW','Hospedaje 23','Calle 23','Ciudad 23',98.6,'Posada','AWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAX','Hospedaje 24','Calle 24','Ciudad 24',99.9,'All Inclusive','AXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAY','Hospedaje 25','Calle 25','Ciudad 25',101.2,'Hotel STD','AYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPAZ','Hospedaje 26','Calle 26','Ciudad 26',102.5,'Posada','AZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBA','Hospedaje 27','Calle 27','Ciudad 27',103.80000000000001,'All Inclusive','BAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBB','Hospedaje 28','Calle 28','Ciudad 28',105.1,'Hotel STD','BBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBC','Hospedaje 29','Calle 29','Ciudad 29',106.4,'Posada','BCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBD','Hospedaje 30','Calle 30','Ciudad 30',107.7,'All Inclusive','BDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBE','Hospedaje 31','Calle 31','Ciudad 31',109.0,'Hotel STD','BEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBF','Hospedaje 32','Calle 32','Ciudad 32',110.30000000000001,'Posada','BFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBG','Hospedaje 33','Calle 33','Ciudad 33',111.6,'All Inclusive','BGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBH','Hospedaje 34','Calle 34','Ciudad 34',112.9,'Hotel STD','BHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBI','Hospedaje 35','Calle 35','Ciudad 35',114.2,'Posada','BIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBJ','Hospedaje 36','Calle 36','Ciudad 36',115.5,'All Inclusive','BJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBK','Hospedaje 37','Calle 37','Ciudad 37',116.80000000000001,'Hotel STD','BKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBL','Hospedaje 38','Calle 38','Ciudad 38',118.1,'Posada','BLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBM','Hospedaje 39','Calle 39','Ciudad 39',119.4,'All Inclusive','BMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBN','Hospedaje 40','Calle 40','Ciudad 40',120.7,'Hotel STD','BNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBO','Hospedaje 41','Calle 41','Ciudad 1',122.0,'Posada','BOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBP','Hospedaje 42','Calle 42','Ciudad 2',123.30000000000001,'All Inclusive','BPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBQ','Hospedaje 43','Calle 43','Ciudad 3',124.6,'Hotel STD','BQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBR','Hospedaje 44','Calle 44','Ciudad 4',125.9,'Posada','BRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBS','Hospedaje 45','Calle 45','Ciudad 5',127.2,'All Inclusive','BSAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBT','Hospedaje 46','Calle 46','Ciudad 6',128.5,'Hotel STD','BTAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBU','Hospedaje 47','Calle 47','Ciudad 7',129.8,'Posada','BUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBV','Hospedaje 48','Calle 48','Ciudad 8',131.1,'All Inclusive','BVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBW','Hospedaje 49','Calle 49','Ciudad 9',132.4,'Hotel STD','BWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBX','Hospedaje 50','Calle 50','Ciudad 10',133.7,'Posada','BXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBY','Hospedaje 51','Calle 51','Ciudad 11',135.0,'All Inclusive','BYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPBZ','Hospedaje 52','Calle 52','Ciudad 12',136.3,'Hotel STD','BZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCA','Hospedaje 53','Calle 53','Ciudad 13',137.60000000000002,'Posada','CAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCB','Hospedaje 54','Calle 54','Ciudad 14',138.9,'All Inclusive','CBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCC','Hospedaje 55','Calle 55','Ciudad 15',140.2,'Hotel STD','CCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCD','Hospedaje 56','Calle 56','Ciudad 16',141.5,'Posada','CDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCE','Hospedaje 57','Calle 57','Ciudad 17',142.8,'All Inclusive','CEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCF','Hospedaje 58','Calle 58','Ciudad 18',144.10000000000002,'Hotel STD','CFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCG','Hospedaje 59','Calle 59','Ciudad 19',145.4,'Posada','CGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCH','Hospedaje 60','Calle 60','Ciudad 20',146.7,'All Inclusive','CHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCI','Hospedaje 61','Calle 61','Ciudad 21',148.0,'Hotel STD','CIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCJ','Hospedaje 62','Calle 62','Ciudad 22',149.3,'Posada','CJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCK','Hospedaje 63','Calle 63','Ciudad 23',150.60000000000002,'All Inclusive','CKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCL','Hospedaje 64','Calle 64','Ciudad 24',151.9,'Hotel STD','CLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCM','Hospedaje 65','Calle 65','Ciudad 25',153.2,'Posada','CMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCN','Hospedaje 66','Calle 66','Ciudad 26',154.5,'All Inclusive','CNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCO','Hospedaje 67','Calle 67','Ciudad 27',155.8,'Hotel STD','COAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCP','Hospedaje 68','Calle 68','Ciudad 28',157.10000000000002,'Posada','CPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCQ','Hospedaje 69','Calle 69','Ciudad 29',158.4,'All Inclusive','CQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCR','Hospedaje 70','Calle 70','Ciudad 30',159.7,'Hotel STD','CRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCS','Hospedaje 71','Calle 71','Ciudad 31',161.0,'Posada','AAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCT','Hospedaje 72','Calle 72','Ciudad 32',162.3,'All Inclusive','ABAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCU','Hospedaje 73','Calle 73','Ciudad 33',163.60000000000002,'Hotel STD','ACAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCV','Hospedaje 74','Calle 74','Ciudad 34',164.9,'Posada','ADAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCW','Hospedaje 75','Calle 75','Ciudad 35',166.2,'All Inclusive','AEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCX','Hospedaje 76','Calle 76','Ciudad 36',167.5,'Hotel STD','AFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCY','Hospedaje 77','Calle 77','Ciudad 37',168.8,'Posada','AGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPCZ','Hospedaje 78','Calle 78','Ciudad 38',170.10000000000002,'All Inclusive','AHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDA','Hospedaje 79','Calle 79','Ciudad 39',171.4,'Hotel STD','AIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDB','Hospedaje 80','Calle 80','Ciudad 40',172.7,'Posada','AJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDC','Hospedaje 81','Calle 81','Ciudad 1',174.0,'All Inclusive','AKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDD','Hospedaje 82','Calle 82','Ciudad 2',175.3,'Hotel STD','ALAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDE','Hospedaje 83','Calle 83','Ciudad 3',176.60000000000002,'Posada','AMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDF','Hospedaje 84','Calle 84','Ciudad 4',177.9,'All Inclusive','ANAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDG','Hospedaje 85','Calle 85','Ciudad 5',179.2,'Hotel STD','AOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDH','Hospedaje 86','Calle 86','Ciudad 6',180.5,'Posada','APAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDI','Hospedaje 87','Calle 87','Ciudad 7',181.8,'All Inclusive','AQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDJ','Hospedaje 88','Calle 88','Ciudad 8',183.10000000000002,'Hotel STD','ARAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDK','Hospedaje 89','Calle 89','Ciudad 9',184.4,'Posada','ASAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDL','Hospedaje 90','Calle 90','Ciudad 10',185.7,'All Inclusive','ATAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDM','Hospedaje 91','Calle 91','Ciudad 11',187.0,'Hotel STD','AUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDN','Hospedaje 92','Calle 92','Ciudad 12',188.3,'Posada','AVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDO','Hospedaje 93','Calle 93','Ciudad 13',189.60000000000002,'All Inclusive','AWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDP','Hospedaje 94','Calle 94','Ciudad 14',190.9,'Hotel STD','AXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDQ','Hospedaje 95','Calle 95','Ciudad 15',192.2,'Posada','AYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDR','Hospedaje 96','Calle 96','Ciudad 16',193.5,'All Inclusive','AZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDS','Hospedaje 97','Calle 97','Ciudad 17',194.8,'Hotel STD','BAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDT','Hospedaje 98','Calle 98','Ciudad 18',196.10000000000002,'Posada','BBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDU','Hospedaje 99','Calle 99','Ciudad 19',197.4,'All Inclusive','BCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDV','Hospedaje 100','Calle 100','Ciudad 20',198.70000000000002,'Hotel STD','BDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDW','Hospedaje 101','Calle 101','Ciudad 21',200.0,'Posada','BEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDX','Hospedaje 102','Calle 102','Ciudad 22',201.3,'All Inclusive','BFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDY','Hospedaje 103','Calle 103','Ciudad 23',202.6,'Hotel STD','BGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPDZ','Hospedaje 104','Calle 104','Ciudad 24',203.9,'Posada','BHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEA','Hospedaje 105','Calle 105','Ciudad 25',205.20000000000002,'All Inclusive','BIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEB','Hospedaje 106','Calle 106','Ciudad 26',206.5,'Hotel STD','BJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEC','Hospedaje 107','Calle 107','Ciudad 27',207.8,'Posada','BKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPED','Hospedaje 108','Calle 108','Ciudad 28',209.1,'All Inclusive','BLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEE','Hospedaje 109','Calle 109','Ciudad 29',210.4,'Hotel STD','BMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEF','Hospedaje 110','Calle 110','Ciudad 30',211.70000000000002,'Posada','BNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEG','Hospedaje 111','Calle 111','Ciudad 31',213.0,'All Inclusive','BOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEH','Hospedaje 112','Calle 112','Ciudad 32',214.3,'Hotel STD','BPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEI','Hospedaje 113','Calle 113','Ciudad 33',215.6,'Posada','BQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEJ','Hospedaje 114','Calle 114','Ciudad 34',216.9,'All Inclusive','BRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEK','Hospedaje 115','Calle 115','Ciudad 35',218.20000000000002,'Hotel STD','BSAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEL','Hospedaje 116','Calle 116','Ciudad 36',219.5,'Posada','BTAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEM','Hospedaje 117','Calle 117','Ciudad 37',220.8,'All Inclusive','BUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEN','Hospedaje 118','Calle 118','Ciudad 38',222.1,'Hotel STD','BVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEO','Hospedaje 119','Calle 119','Ciudad 39',223.4,'Posada','BWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEP','Hospedaje 120','Calle 120','Ciudad 40',224.70000000000002,'All Inclusive','BXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEQ','Hospedaje 121','Calle 121','Ciudad 1',226.0,'Hotel STD','BYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPER','Hospedaje 122','Calle 122','Ciudad 2',227.3,'Posada','BZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPES','Hospedaje 123','Calle 123','Ciudad 3',228.6,'All Inclusive','CAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPET','Hospedaje 124','Calle 124','Ciudad 4',229.9,'Hotel STD','CBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEU','Hospedaje 125','Calle 125','Ciudad 5',231.20000000000002,'Posada','CCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEV','Hospedaje 126','Calle 126','Ciudad 6',232.5,'All Inclusive','CDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEW','Hospedaje 127','Calle 127','Ciudad 7',233.8,'Hotel STD','CEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEX','Hospedaje 128','Calle 128','Ciudad 8',235.1,'Posada','CFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEY','Hospedaje 129','Calle 129','Ciudad 9',236.4,'All Inclusive','CGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPEZ','Hospedaje 130','Calle 130','Ciudad 10',237.70000000000002,'Hotel STD','CHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFA','Hospedaje 131','Calle 131','Ciudad 11',239.0,'Posada','CIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFB','Hospedaje 132','Calle 132','Ciudad 12',240.3,'All Inclusive','CJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFC','Hospedaje 133','Calle 133','Ciudad 13',241.6,'Hotel STD','CKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFD','Hospedaje 134','Calle 134','Ciudad 14',242.9,'Posada','CLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFE','Hospedaje 135','Calle 135','Ciudad 15',244.20000000000002,'All Inclusive','CMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFF','Hospedaje 136','Calle 136','Ciudad 16',245.5,'Hotel STD','CNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFG','Hospedaje 137','Calle 137','Ciudad 17',246.8,'Posada','COAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFH','Hospedaje 138','Calle 138','Ciudad 18',248.1,'All Inclusive','CPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFI','Hospedaje 139','Calle 139','Ciudad 19',249.4,'Hotel STD','CQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFJ','Hospedaje 140','Calle 140','Ciudad 20',250.70000000000002,'Posada','CRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFK','Hospedaje 141','Calle 141','Ciudad 21',252.0,'All Inclusive','AAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFL','Hospedaje 142','Calle 142','Ciudad 22',253.3,'Hotel STD','ABAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFM','Hospedaje 143','Calle 143','Ciudad 23',254.6,'Posada','ACAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFN','Hospedaje 144','Calle 144','Ciudad 24',255.9,'All Inclusive','ADAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFO','Hospedaje 145','Calle 145','Ciudad 25',257.20000000000005,'Hotel STD','AEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFP','Hospedaje 146','Calle 146','Ciudad 26',258.5,'Posada','AFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFQ','Hospedaje 147','Calle 147','Ciudad 27',259.8,'All Inclusive','AGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFR','Hospedaje 148','Calle 148','Ciudad 28',261.1,'Hotel STD','AHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFS','Hospedaje 149','Calle 149','Ciudad 29',262.4,'Posada','AIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFT','Hospedaje 150','Calle 150','Ciudad 30',263.70000000000005,'All Inclusive','AJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFU','Hospedaje 151','Calle 151','Ciudad 31',265.0,'Hotel STD','AKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFV','Hospedaje 152','Calle 152','Ciudad 32',266.3,'Posada','ALAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFW','Hospedaje 153','Calle 153','Ciudad 33',267.6,'All Inclusive','AMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFX','Hospedaje 154','Calle 154','Ciudad 34',268.9,'Hotel STD','ANAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFY','Hospedaje 155','Calle 155','Ciudad 35',270.20000000000005,'Posada','AOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPFZ','Hospedaje 156','Calle 156','Ciudad 36',271.5,'All Inclusive','APAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGA','Hospedaje 157','Calle 157','Ciudad 37',272.8,'Hotel STD','AQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGB','Hospedaje 158','Calle 158','Ciudad 38',274.1,'Posada','ARAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGC','Hospedaje 159','Calle 159','Ciudad 39',275.4,'All Inclusive','ASAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGD','Hospedaje 160','Calle 160','Ciudad 40',276.70000000000005,'Hotel STD','ATAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGE','Hospedaje 161','Calle 161','Ciudad 1',278.0,'Posada','AUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGF','Hospedaje 162','Calle 162','Ciudad 2',279.3,'All Inclusive','AVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGG','Hospedaje 163','Calle 163','Ciudad 3',280.6,'Hotel STD','AWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGH','Hospedaje 164','Calle 164','Ciudad 4',281.9,'Posada','AXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGI','Hospedaje 165','Calle 165','Ciudad 5',283.20000000000005,'All Inclusive','AYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGJ','Hospedaje 166','Calle 166','Ciudad 6',284.5,'Hotel STD','AZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGK','Hospedaje 167','Calle 167','Ciudad 7',285.8,'Posada','BAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGL','Hospedaje 168','Calle 168','Ciudad 8',287.1,'All Inclusive','BBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGM','Hospedaje 169','Calle 169','Ciudad 9',288.4,'Hotel STD','BCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGN','Hospedaje 170','Calle 170','Ciudad 10',289.70000000000005,'Posada','BDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGO','Hospedaje 171','Calle 171','Ciudad 11',291.0,'All Inclusive','BEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGP','Hospedaje 172','Calle 172','Ciudad 12',292.3,'Hotel STD','BFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGQ','Hospedaje 173','Calle 173','Ciudad 13',293.6,'Posada','BGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGR','Hospedaje 174','Calle 174','Ciudad 14',294.9,'All Inclusive','BHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGS','Hospedaje 175','Calle 175','Ciudad 15',296.20000000000005,'Hotel STD','BIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGT','Hospedaje 176','Calle 176','Ciudad 16',297.5,'Posada','BJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGU','Hospedaje 177','Calle 177','Ciudad 17',298.8,'All Inclusive','BKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGV','Hospedaje 178','Calle 178','Ciudad 18',300.1,'Hotel STD','BLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGW','Hospedaje 179','Calle 179','Ciudad 19',301.4,'Posada','BMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGX','Hospedaje 180','Calle 180','Ciudad 20',302.70000000000005,'All Inclusive','BNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGY','Hospedaje 181','Calle 181','Ciudad 21',304.0,'Hotel STD','BOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPGZ','Hospedaje 182','Calle 182','Ciudad 22',305.3,'Posada','BPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHA','Hospedaje 183','Calle 183','Ciudad 23',306.6,'All Inclusive','BQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHB','Hospedaje 184','Calle 184','Ciudad 24',307.9,'Hotel STD','BRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHC','Hospedaje 185','Calle 185','Ciudad 25',309.20000000000005,'Posada','BSAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHD','Hospedaje 186','Calle 186','Ciudad 26',310.5,'All Inclusive','BTAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHE','Hospedaje 187','Calle 187','Ciudad 27',311.8,'Hotel STD','BUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHF','Hospedaje 188','Calle 188','Ciudad 28',313.1,'Posada','BVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHG','Hospedaje 189','Calle 189','Ciudad 29',314.4,'All Inclusive','BWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHH','Hospedaje 190','Calle 190','Ciudad 30',315.70000000000005,'Hotel STD','BXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHI','Hospedaje 191','Calle 191','Ciudad 31',317.0,'Posada','BYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHJ','Hospedaje 192','Calle 192','Ciudad 32',318.3,'All Inclusive','BZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHK','Hospedaje 193','Calle 193','Ciudad 33',319.6,'Hotel STD','CAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHL','Hospedaje 194','Calle 194','Ciudad 34',320.9,'Posada','CBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHM','Hospedaje 195','Calle 195','Ciudad 35',322.20000000000005,'All Inclusive','CCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHN','Hospedaje 196','Calle 196','Ciudad 36',323.5,'Hotel STD','CDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHO','Hospedaje 197','Calle 197','Ciudad 37',324.8,'Posada','CEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHP','Hospedaje 198','Calle 198','Ciudad 38',326.1,'All Inclusive','CFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHQ','Hospedaje 199','Calle 199','Ciudad 39',327.40000000000003,'Hotel STD','CGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHR','Hospedaje 200','Calle 200','Ciudad 40',328.7,'Posada','CHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHS','Hospedaje 201','Calle 201','Ciudad 1',330.0,'All Inclusive','CIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHT','Hospedaje 202','Calle 202','Ciudad 2',331.3,'Hotel STD','CJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHU','Hospedaje 203','Calle 203','Ciudad 3',332.6,'Posada','CKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHV','Hospedaje 204','Calle 204','Ciudad 4',333.90000000000003,'All Inclusive','CLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHW','Hospedaje 205','Calle 205','Ciudad 5',335.2,'Hotel STD','CMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHX','Hospedaje 206','Calle 206','Ciudad 6',336.5,'Posada','CNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHY','Hospedaje 207','Calle 207','Ciudad 7',337.8,'All Inclusive','COAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPHZ','Hospedaje 208','Calle 208','Ciudad 8',339.1,'Hotel STD','CPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIA','Hospedaje 209','Calle 209','Ciudad 9',340.40000000000003,'Posada','CQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIB','Hospedaje 210','Calle 210','Ciudad 10',341.7,'All Inclusive','CRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIC','Hospedaje 211','Calle 211','Ciudad 11',343.0,'Hotel STD','AAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPID','Hospedaje 212','Calle 212','Ciudad 12',344.3,'Posada','ABAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIE','Hospedaje 213','Calle 213','Ciudad 13',345.6,'All Inclusive','ACAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIF','Hospedaje 214','Calle 214','Ciudad 14',346.90000000000003,'Hotel STD','ADAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIG','Hospedaje 215','Calle 215','Ciudad 15',348.2,'Posada','AEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIH','Hospedaje 216','Calle 216','Ciudad 16',349.5,'All Inclusive','AFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPII','Hospedaje 217','Calle 217','Ciudad 17',350.8,'Hotel STD','AGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIJ','Hospedaje 218','Calle 218','Ciudad 18',352.1,'Posada','AHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIK','Hospedaje 219','Calle 219','Ciudad 19',353.40000000000003,'All Inclusive','AIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIL','Hospedaje 220','Calle 220','Ciudad 20',354.7,'Hotel STD','AJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIM','Hospedaje 221','Calle 221','Ciudad 21',356.0,'Posada','AKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIN','Hospedaje 222','Calle 222','Ciudad 22',357.3,'All Inclusive','ALAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIO','Hospedaje 223','Calle 223','Ciudad 23',358.6,'Hotel STD','AMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIP','Hospedaje 224','Calle 224','Ciudad 24',359.90000000000003,'Posada','ANAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIQ','Hospedaje 225','Calle 225','Ciudad 25',361.2,'All Inclusive','AOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIR','Hospedaje 226','Calle 226','Ciudad 26',362.5,'Hotel STD','APAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIS','Hospedaje 227','Calle 227','Ciudad 27',363.8,'Posada','AQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIT','Hospedaje 228','Calle 228','Ciudad 28',365.1,'All Inclusive','ARAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIU','Hospedaje 229','Calle 229','Ciudad 29',366.40000000000003,'Hotel STD','ASAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIV','Hospedaje 230','Calle 230','Ciudad 30',367.7,'Posada','ATAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIW','Hospedaje 231','Calle 231','Ciudad 31',369.0,'All Inclusive','AUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIX','Hospedaje 232','Calle 232','Ciudad 32',370.3,'Hotel STD','AVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIY','Hospedaje 233','Calle 233','Ciudad 33',371.6,'Posada','AWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPIZ','Hospedaje 234','Calle 234','Ciudad 34',372.90000000000003,'All Inclusive','AXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJA','Hospedaje 235','Calle 235','Ciudad 35',374.2,'Hotel STD','AYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJB','Hospedaje 236','Calle 236','Ciudad 36',375.5,'Posada','AZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJC','Hospedaje 237','Calle 237','Ciudad 37',376.8,'All Inclusive','BAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJD','Hospedaje 238','Calle 238','Ciudad 38',378.1,'Hotel STD','BBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJE','Hospedaje 239','Calle 239','Ciudad 39',379.40000000000003,'Posada','BCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJF','Hospedaje 240','Calle 240','Ciudad 40',380.7,'All Inclusive','BDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJG','Hospedaje 241','Calle 241','Ciudad 1',382.0,'Hotel STD','BEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJH','Hospedaje 242','Calle 242','Ciudad 2',383.3,'Posada','BFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJI','Hospedaje 243','Calle 243','Ciudad 3',384.6,'All Inclusive','BGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJJ','Hospedaje 244','Calle 244','Ciudad 4',385.90000000000003,'Hotel STD','BHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJK','Hospedaje 245','Calle 245','Ciudad 5',387.2,'Posada','BIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJL','Hospedaje 246','Calle 246','Ciudad 6',388.5,'All Inclusive','BJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJM','Hospedaje 247','Calle 247','Ciudad 7',389.8,'Hotel STD','BKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJN','Hospedaje 248','Calle 248','Ciudad 8',391.1,'Posada','BLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJO','Hospedaje 249','Calle 249','Ciudad 9',392.40000000000003,'All Inclusive','BMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJP','Hospedaje 250','Calle 250','Ciudad 10',393.7,'Hotel STD','BNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJQ','Hospedaje 251','Calle 251','Ciudad 11',395.0,'Posada','BOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJR','Hospedaje 252','Calle 252','Ciudad 12',396.3,'All Inclusive','BPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJS','Hospedaje 253','Calle 253','Ciudad 13',397.6,'Hotel STD','BQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJT','Hospedaje 254','Calle 254','Ciudad 14',398.90000000000003,'Posada','BRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJU','Hospedaje 255','Calle 255','Ciudad 15',400.2,'All Inclusive','BSAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJV','Hospedaje 256','Calle 256','Ciudad 16',401.5,'Hotel STD','BTAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJW','Hospedaje 257','Calle 257','Ciudad 17',402.8,'Posada','BUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJX','Hospedaje 258','Calle 258','Ciudad 18',404.1,'All Inclusive','BVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJY','Hospedaje 259','Calle 259','Ciudad 19',405.40000000000003,'Hotel STD','BWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPJZ','Hospedaje 260','Calle 260','Ciudad 20',406.7,'Posada','BXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKA','Hospedaje 261','Calle 261','Ciudad 21',408.0,'All Inclusive','BYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKB','Hospedaje 262','Calle 262','Ciudad 22',409.3,'Hotel STD','BZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKC','Hospedaje 263','Calle 263','Ciudad 23',410.6,'Posada','CAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKD','Hospedaje 264','Calle 264','Ciudad 24',411.90000000000003,'All Inclusive','CBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKE','Hospedaje 265','Calle 265','Ciudad 25',413.2,'Hotel STD','CCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKF','Hospedaje 266','Calle 266','Ciudad 26',414.5,'Posada','CDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKG','Hospedaje 267','Calle 267','Ciudad 27',415.8,'All Inclusive','CEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKH','Hospedaje 268','Calle 268','Ciudad 28',417.1,'Hotel STD','CFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKI','Hospedaje 269','Calle 269','Ciudad 29',418.40000000000003,'Posada','CGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKJ','Hospedaje 270','Calle 270','Ciudad 30',419.7,'All Inclusive','CHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKK','Hospedaje 271','Calle 271','Ciudad 31',421.0,'Hotel STD','CIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKL','Hospedaje 272','Calle 272','Ciudad 32',422.3,'Posada','CJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKM','Hospedaje 273','Calle 273','Ciudad 33',423.6,'All Inclusive','CKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKN','Hospedaje 274','Calle 274','Ciudad 34',424.90000000000003,'Hotel STD','CLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKO','Hospedaje 275','Calle 275','Ciudad 35',426.2,'Posada','CMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKP','Hospedaje 276','Calle 276','Ciudad 36',427.5,'All Inclusive','CNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKQ','Hospedaje 277','Calle 277','Ciudad 37',428.8,'Hotel STD','COAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKR','Hospedaje 278','Calle 278','Ciudad 38',430.1,'Posada','CPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKS','Hospedaje 279','Calle 279','Ciudad 39',431.40000000000003,'All Inclusive','CQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKT','Hospedaje 280','Calle 280','Ciudad 40',432.7,'Hotel STD','CRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKU','Hospedaje 281','Calle 281','Ciudad 1',434.0,'Posada','AAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKV','Hospedaje 282','Calle 282','Ciudad 2',435.3,'All Inclusive','ABAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKW','Hospedaje 283','Calle 283','Ciudad 3',436.6,'Hotel STD','ACAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKX','Hospedaje 284','Calle 284','Ciudad 4',437.90000000000003,'Posada','ADAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKY','Hospedaje 285','Calle 285','Ciudad 5',439.2,'All Inclusive','AEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPKZ','Hospedaje 286','Calle 286','Ciudad 6',440.5,'Hotel STD','AFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLA','Hospedaje 287','Calle 287','Ciudad 7',441.8,'Posada','AGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLB','Hospedaje 288','Calle 288','Ciudad 8',443.1,'All Inclusive','AHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLC','Hospedaje 289','Calle 289','Ciudad 9',444.40000000000003,'Hotel STD','AIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLD','Hospedaje 290','Calle 290','Ciudad 10',445.7,'Posada','AJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLE','Hospedaje 291','Calle 291','Ciudad 11',447.0,'All Inclusive','AKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLF','Hospedaje 292','Calle 292','Ciudad 12',448.3,'Hotel STD','ALAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLG','Hospedaje 293','Calle 293','Ciudad 13',449.6,'Posada','AMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLH','Hospedaje 294','Calle 294','Ciudad 14',450.90000000000003,'All Inclusive','ANAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLI','Hospedaje 295','Calle 295','Ciudad 15',452.2,'Hotel STD','AOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLJ','Hospedaje 296','Calle 296','Ciudad 16',453.5,'Posada','APAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLK','Hospedaje 297','Calle 297','Ciudad 17',454.8,'All Inclusive','AQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLL','Hospedaje 298','Calle 298','Ciudad 18',456.1,'Hotel STD','ARAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLM','Hospedaje 299','Calle 299','Ciudad 19',457.40000000000003,'Posada','ASAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLN','Hospedaje 300','Calle 300','Ciudad 20',458.7,'All Inclusive','ATAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLO','Hospedaje 301','Calle 301','Ciudad 21',460.0,'Hotel STD','AUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLP','Hospedaje 302','Calle 302','Ciudad 22',461.3,'Posada','AVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLQ','Hospedaje 303','Calle 303','Ciudad 23',462.6,'All Inclusive','AWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLR','Hospedaje 304','Calle 304','Ciudad 24',463.90000000000003,'Hotel STD','AXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLS','Hospedaje 305','Calle 305','Ciudad 25',465.2,'Posada','AYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLT','Hospedaje 306','Calle 306','Ciudad 26',466.5,'All Inclusive','AZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLU','Hospedaje 307','Calle 307','Ciudad 27',467.8,'Hotel STD','BAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLV','Hospedaje 308','Calle 308','Ciudad 28',469.1,'Posada','BBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLW','Hospedaje 309','Calle 309','Ciudad 29',470.40000000000003,'All Inclusive','BCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLX','Hospedaje 310','Calle 310','Ciudad 30',471.7,'Hotel STD','BDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLY','Hospedaje 311','Calle 311','Ciudad 31',473.0,'Posada','BEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPLZ','Hospedaje 312','Calle 312','Ciudad 32',474.3,'All Inclusive','BFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMA','Hospedaje 313','Calle 313','Ciudad 33',475.6,'Hotel STD','BGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMB','Hospedaje 314','Calle 314','Ciudad 34',476.90000000000003,'Posada','BHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMC','Hospedaje 315','Calle 315','Ciudad 35',478.2,'All Inclusive','BIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMD','Hospedaje 316','Calle 316','Ciudad 36',479.5,'Hotel STD','BJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPME','Hospedaje 317','Calle 317','Ciudad 37',480.8,'Posada','BKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMF','Hospedaje 318','Calle 318','Ciudad 38',482.1,'All Inclusive','BLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMG','Hospedaje 319','Calle 319','Ciudad 39',483.40000000000003,'Hotel STD','BMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMH','Hospedaje 320','Calle 320','Ciudad 40',484.7,'Posada','BNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMI','Hospedaje 321','Calle 321','Ciudad 1',486.0,'All Inclusive','BOAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMJ','Hospedaje 322','Calle 322','Ciudad 2',487.3,'Hotel STD','BPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMK','Hospedaje 323','Calle 323','Ciudad 3',488.6,'Posada','BQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPML','Hospedaje 324','Calle 324','Ciudad 4',489.90000000000003,'All Inclusive','BRAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMM','Hospedaje 325','Calle 325','Ciudad 5',491.2,'Hotel STD','BSAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMN','Hospedaje 326','Calle 326','Ciudad 6',492.5,'Posada','BTAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMO','Hospedaje 327','Calle 327','Ciudad 7',493.8,'All Inclusive','BUAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMP','Hospedaje 328','Calle 328','Ciudad 8',495.1,'Hotel STD','BVAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMQ','Hospedaje 329','Calle 329','Ciudad 9',496.40000000000003,'Posada','BWAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMR','Hospedaje 330','Calle 330','Ciudad 10',497.7,'All Inclusive','BXAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMS','Hospedaje 331','Calle 331','Ciudad 11',499.0,'Hotel STD','BYAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMT','Hospedaje 332','Calle 332','Ciudad 12',500.3,'Posada','BZAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMU','Hospedaje 333','Calle 333','Ciudad 13',501.6,'All Inclusive','CAAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMV','Hospedaje 334','Calle 334','Ciudad 14',502.90000000000003,'Hotel STD','CBAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMW','Hospedaje 335','Calle 335','Ciudad 15',504.2,'Posada','CCAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMX','Hospedaje 336','Calle 336','Ciudad 16',505.5,'All Inclusive','CDAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMY','Hospedaje 337','Calle 337','Ciudad 17',506.8,'Hotel STD','CEAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPMZ','Hospedaje 338','Calle 338','Ciudad 18',508.1,'Posada','CFAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNA','Hospedaje 339','Calle 339','Ciudad 19',509.40000000000003,'All Inclusive','CGAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNB','Hospedaje 340','Calle 340','Ciudad 20',510.7,'Hotel STD','CHAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNC','Hospedaje 341','Calle 341','Ciudad 21',512.0,'Posada','CIAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPND','Hospedaje 342','Calle 342','Ciudad 22',513.3,'All Inclusive','CJAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNE','Hospedaje 343','Calle 343','Ciudad 23',514.6,'Hotel STD','CKAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNF','Hospedaje 344','Calle 344','Ciudad 24',515.9000000000001,'Posada','CLAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNG','Hospedaje 345','Calle 345','Ciudad 25',517.2,'All Inclusive','CMAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNH','Hospedaje 346','Calle 346','Ciudad 26',518.5,'Hotel STD','CNAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNI','Hospedaje 347','Calle 347','Ciudad 27',519.8,'Posada','COAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNJ','Hospedaje 348','Calle 348','Ciudad 28',521.1,'All Inclusive','CPAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNK','Hospedaje 349','Calle 349','Ciudad 29',522.4000000000001,'Hotel STD','CQAA');
INSERT INTO Hospedajes (codigoInterno,nombre,calle,localidad,precioH,tipoH,estadoCodigo) VALUES ('HOSPNL','Hospedaje 350','Calle 350','Ciudad 30',523.7,'Posada','CRAA');

-- PAQUETES VIAJES
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 1','Descripcion paquete 1',4,403,523,663,'emp01','VUELO00001','VUELO00002','ABAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 2','Descripcion paquete 2',5,406,526,666,'emp02','VUELO00002','VUELO00003','ACAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 3','Descripcion paquete 3',6,409,529,669,'emp03','VUELO00003','VUELO00004','ADAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 4','Descripcion paquete 4',7,412,532,672,'emp04','VUELO00004','VUELO00005','AEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 5','Descripcion paquete 5',8,415,535,675,'emp05','VUELO00005','VUELO00006','AFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 6','Descripcion paquete 6',9,418,538,678,'emp06','VUELO00006','VUELO00007','AGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 7','Descripcion paquete 7',10,421,541,681,'emp07','VUELO00007','VUELO00008','AHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 8','Descripcion paquete 8',11,424,544,684,'emp08','VUELO00008','VUELO00009','AIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 9','Descripcion paquete 9',12,427,547,687,'emp09','VUELO00009','VUELO00010','AJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 10','Descripcion paquete 10',3,430,550,690,'emp10','VUELO00010','VUELO00011','AKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 11','Descripcion paquete 11',4,433,553,693,'emp11','VUELO00011','VUELO00012','ALAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 12','Descripcion paquete 12',5,436,556,696,'emp12','VUELO00012','VUELO00013','AMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 13','Descripcion paquete 13',6,439,559,699,'emp13','VUELO00013','VUELO00014','ANAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 14','Descripcion paquete 14',7,442,562,702,'emp14','VUELO00014','VUELO00015','AOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 15','Descripcion paquete 15',8,445,565,705,'emp15','VUELO00015','VUELO00016','APAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 16','Descripcion paquete 16',9,448,568,708,'emp01','VUELO00016','VUELO00017','AQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 17','Descripcion paquete 17',10,451,571,711,'emp02','VUELO00017','VUELO00018','ARAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 18','Descripcion paquete 18',11,454,574,714,'emp03','VUELO00018','VUELO00019','ASAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 19','Descripcion paquete 19',12,457,577,717,'emp04','VUELO00019','VUELO00020','ATAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 20','Descripcion paquete 20',3,460,580,720,'emp05','VUELO00020','VUELO00021','AUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 21','Descripcion paquete 21',4,463,583,723,'emp06','VUELO00021','VUELO00022','AVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 22','Descripcion paquete 22',5,466,586,726,'emp07','VUELO00022','VUELO00023','AWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 23','Descripcion paquete 23',6,469,589,729,'emp08','VUELO00023','VUELO00024','AXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 24','Descripcion paquete 24',7,472,592,732,'emp09','VUELO00024','VUELO00025','AYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 25','Descripcion paquete 25',8,475,595,735,'emp10','VUELO00025','VUELO00026','AZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 26','Descripcion paquete 26',9,478,598,738,'emp11','VUELO00026','VUELO00027','BAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 27','Descripcion paquete 27',10,481,601,741,'emp12','VUELO00027','VUELO00028','BBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 28','Descripcion paquete 28',11,484,604,744,'emp13','VUELO00028','VUELO00029','BCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 29','Descripcion paquete 29',12,487,607,747,'emp14','VUELO00029','VUELO00030','BDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 30','Descripcion paquete 30',3,490,610,750,'emp15','VUELO00030','VUELO00031','BEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 31','Descripcion paquete 31',4,493,613,753,'emp01','VUELO00031','VUELO00032','BFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 32','Descripcion paquete 32',5,496,616,756,'emp02','VUELO00032','VUELO00033','BGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 33','Descripcion paquete 33',6,499,619,759,'emp03','VUELO00033','VUELO00034','BHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 34','Descripcion paquete 34',7,502,622,762,'emp04','VUELO00034','VUELO00035','BIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 35','Descripcion paquete 35',8,505,625,765,'emp05','VUELO00035','VUELO00036','BJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 36','Descripcion paquete 36',9,508,628,768,'emp06','VUELO00036','VUELO00037','BKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 37','Descripcion paquete 37',10,511,631,771,'emp07','VUELO00037','VUELO00038','BLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 38','Descripcion paquete 38',11,514,634,774,'emp08','VUELO00038','VUELO00039','BMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 39','Descripcion paquete 39',12,517,637,777,'emp09','VUELO00039','VUELO00040','BNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 40','Descripcion paquete 40',3,520,640,780,'emp10','VUELO00040','VUELO00041','BOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 41','Descripcion paquete 41',4,523,643,783,'emp11','VUELO00041','VUELO00042','BPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 42','Descripcion paquete 42',5,526,646,786,'emp12','VUELO00042','VUELO00043','BQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 43','Descripcion paquete 43',6,529,649,789,'emp13','VUELO00043','VUELO00044','BRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 44','Descripcion paquete 44',7,532,652,792,'emp14','VUELO00044','VUELO00045','BSAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 45','Descripcion paquete 45',8,535,655,795,'emp15','VUELO00045','VUELO00046','BTAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 46','Descripcion paquete 46',9,538,658,798,'emp01','VUELO00046','VUELO00047','BUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 47','Descripcion paquete 47',10,541,661,801,'emp02','VUELO00047','VUELO00048','BVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 48','Descripcion paquete 48',11,544,664,804,'emp03','VUELO00048','VUELO00049','BWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 49','Descripcion paquete 49',12,547,667,807,'emp04','VUELO00049','VUELO00050','BXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 50','Descripcion paquete 50',3,550,670,810,'emp05','VUELO00050','VUELO00051','BYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 51','Descripcion paquete 51',4,553,673,813,'emp06','VUELO00051','VUELO00052','BZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 52','Descripcion paquete 52',5,556,676,816,'emp07','VUELO00052','VUELO00053','CAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 53','Descripcion paquete 53',6,559,679,819,'emp08','VUELO00053','VUELO00054','CBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 54','Descripcion paquete 54',7,562,682,822,'emp09','VUELO00054','VUELO00055','CCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 55','Descripcion paquete 55',8,565,685,825,'emp10','VUELO00055','VUELO00056','CDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 56','Descripcion paquete 56',9,568,688,828,'emp11','VUELO00056','VUELO00057','CEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 57','Descripcion paquete 57',10,571,691,831,'emp12','VUELO00057','VUELO00058','CFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 58','Descripcion paquete 58',11,574,694,834,'emp13','VUELO00058','VUELO00059','CGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 59','Descripcion paquete 59',12,577,697,837,'emp14','VUELO00059','VUELO00060','CHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 60','Descripcion paquete 60',3,580,700,840,'emp15','VUELO00060','VUELO00061','CIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 61','Descripcion paquete 61',4,583,703,843,'emp01','VUELO00061','VUELO00062','CJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 62','Descripcion paquete 62',5,586,706,846,'emp02','VUELO00062','VUELO00063','CKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 63','Descripcion paquete 63',6,589,709,849,'emp03','VUELO00063','VUELO00064','CLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 64','Descripcion paquete 64',7,592,712,852,'emp04','VUELO00064','VUELO00065','CMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 65','Descripcion paquete 65',8,595,715,855,'emp05','VUELO00065','VUELO00066','CNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 66','Descripcion paquete 66',9,598,718,858,'emp06','VUELO00066','VUELO00067','COAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 67','Descripcion paquete 67',10,601,721,861,'emp07','VUELO00067','VUELO00068','CPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 68','Descripcion paquete 68',11,604,724,864,'emp08','VUELO00068','VUELO00069','CQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 69','Descripcion paquete 69',12,607,727,867,'emp09','VUELO00069','VUELO00070','CRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 70','Descripcion paquete 70',3,610,730,870,'emp10','VUELO00070','VUELO00071','AAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 71','Descripcion paquete 71',4,613,733,873,'emp11','VUELO00071','VUELO00072','ABAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 72','Descripcion paquete 72',5,616,736,876,'emp12','VUELO00072','VUELO00073','ACAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 73','Descripcion paquete 73',6,619,739,879,'emp13','VUELO00073','VUELO00074','ADAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 74','Descripcion paquete 74',7,622,742,882,'emp14','VUELO00074','VUELO00075','AEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 75','Descripcion paquete 75',8,625,745,885,'emp15','VUELO00075','VUELO00076','AFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 76','Descripcion paquete 76',9,628,748,888,'emp01','VUELO00076','VUELO00077','AGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 77','Descripcion paquete 77',10,631,751,891,'emp02','VUELO00077','VUELO00078','AHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 78','Descripcion paquete 78',11,634,754,894,'emp03','VUELO00078','VUELO00079','AIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 79','Descripcion paquete 79',12,637,757,897,'emp04','VUELO00079','VUELO00080','AJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 80','Descripcion paquete 80',3,640,760,900,'emp05','VUELO00080','VUELO00081','AKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 81','Descripcion paquete 81',4,643,763,903,'emp06','VUELO00081','VUELO00082','ALAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 82','Descripcion paquete 82',5,646,766,906,'emp07','VUELO00082','VUELO00083','AMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 83','Descripcion paquete 83',6,649,769,909,'emp08','VUELO00083','VUELO00084','ANAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 84','Descripcion paquete 84',7,652,772,912,'emp09','VUELO00084','VUELO00085','AOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 85','Descripcion paquete 85',8,655,775,915,'emp10','VUELO00085','VUELO00086','APAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 86','Descripcion paquete 86',9,658,778,918,'emp11','VUELO00086','VUELO00087','AQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 87','Descripcion paquete 87',10,661,781,921,'emp12','VUELO00087','VUELO00088','ARAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 88','Descripcion paquete 88',11,664,784,924,'emp13','VUELO00088','VUELO00089','ASAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 89','Descripcion paquete 89',12,667,787,927,'emp14','VUELO00089','VUELO00090','ATAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 90','Descripcion paquete 90',3,670,790,930,'emp15','VUELO00090','VUELO00091','AUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 91','Descripcion paquete 91',4,673,793,933,'emp01','VUELO00091','VUELO00092','AVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 92','Descripcion paquete 92',5,676,796,936,'emp02','VUELO00092','VUELO00093','AWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 93','Descripcion paquete 93',6,679,799,939,'emp03','VUELO00093','VUELO00094','AXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 94','Descripcion paquete 94',7,682,802,942,'emp04','VUELO00094','VUELO00095','AYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 95','Descripcion paquete 95',8,685,805,945,'emp05','VUELO00095','VUELO00096','AZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 96','Descripcion paquete 96',9,688,808,948,'emp06','VUELO00096','VUELO00097','BAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 97','Descripcion paquete 97',10,691,811,951,'emp07','VUELO00097','VUELO00098','BBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 98','Descripcion paquete 98',11,694,814,954,'emp08','VUELO00098','VUELO00099','BCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 99','Descripcion paquete 99',12,697,817,957,'emp09','VUELO00099','VUELO00100','BDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 100','Descripcion paquete 100',3,700,820,960,'emp10','VUELO00100','VUELO00101','BEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 101','Descripcion paquete 101',4,703,823,963,'emp11','VUELO00101','VUELO00102','BFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 102','Descripcion paquete 102',5,706,826,966,'emp12','VUELO00102','VUELO00103','BGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 103','Descripcion paquete 103',6,709,829,969,'emp13','VUELO00103','VUELO00104','BHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 104','Descripcion paquete 104',7,712,832,972,'emp14','VUELO00104','VUELO00105','BIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 105','Descripcion paquete 105',8,715,835,975,'emp15','VUELO00105','VUELO00106','BJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 106','Descripcion paquete 106',9,718,838,978,'emp01','VUELO00106','VUELO00107','BKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 107','Descripcion paquete 107',10,721,841,981,'emp02','VUELO00107','VUELO00108','BLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 108','Descripcion paquete 108',11,724,844,984,'emp03','VUELO00108','VUELO00109','BMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 109','Descripcion paquete 109',12,727,847,987,'emp04','VUELO00109','VUELO00110','BNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 110','Descripcion paquete 110',3,730,850,990,'emp05','VUELO00110','VUELO00111','BOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 111','Descripcion paquete 111',4,733,853,993,'emp06','VUELO00111','VUELO00112','BPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 112','Descripcion paquete 112',5,736,856,996,'emp07','VUELO00112','VUELO00113','BQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 113','Descripcion paquete 113',6,739,859,999,'emp08','VUELO00113','VUELO00114','BRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 114','Descripcion paquete 114',7,742,862,1002,'emp09','VUELO00114','VUELO00115','BSAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 115','Descripcion paquete 115',8,745,865,1005,'emp10','VUELO00115','VUELO00116','BTAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 116','Descripcion paquete 116',9,748,868,1008,'emp11','VUELO00116','VUELO00117','BUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 117','Descripcion paquete 117',10,751,871,1011,'emp12','VUELO00117','VUELO00118','BVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 118','Descripcion paquete 118',11,754,874,1014,'emp13','VUELO00118','VUELO00119','BWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 119','Descripcion paquete 119',12,757,877,1017,'emp14','VUELO00119','VUELO00120','BXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 120','Descripcion paquete 120',3,760,880,1020,'emp15','VUELO00120','VUELO00121','BYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 121','Descripcion paquete 121',4,763,883,1023,'emp01','VUELO00121','VUELO00122','BZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 122','Descripcion paquete 122',5,766,886,1026,'emp02','VUELO00122','VUELO00123','CAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 123','Descripcion paquete 123',6,769,889,1029,'emp03','VUELO00123','VUELO00124','CBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 124','Descripcion paquete 124',7,772,892,1032,'emp04','VUELO00124','VUELO00125','CCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 125','Descripcion paquete 125',8,775,895,1035,'emp05','VUELO00125','VUELO00126','CDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 126','Descripcion paquete 126',9,778,898,1038,'emp06','VUELO00126','VUELO00127','CEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 127','Descripcion paquete 127',10,781,901,1041,'emp07','VUELO00127','VUELO00128','CFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 128','Descripcion paquete 128',11,784,904,1044,'emp08','VUELO00128','VUELO00129','CGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 129','Descripcion paquete 129',12,787,907,1047,'emp09','VUELO00129','VUELO00130','CHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 130','Descripcion paquete 130',3,790,910,1050,'emp10','VUELO00130','VUELO00131','CIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 131','Descripcion paquete 131',4,793,913,1053,'emp11','VUELO00131','VUELO00132','CJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 132','Descripcion paquete 132',5,796,916,1056,'emp12','VUELO00132','VUELO00133','CKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 133','Descripcion paquete 133',6,799,919,1059,'emp13','VUELO00133','VUELO00134','CLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 134','Descripcion paquete 134',7,802,922,1062,'emp14','VUELO00134','VUELO00135','CMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 135','Descripcion paquete 135',8,805,925,1065,'emp15','VUELO00135','VUELO00136','CNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 136','Descripcion paquete 136',9,808,928,1068,'emp01','VUELO00136','VUELO00137','COAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 137','Descripcion paquete 137',10,811,931,1071,'emp02','VUELO00137','VUELO00138','CPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 138','Descripcion paquete 138',11,814,934,1074,'emp03','VUELO00138','VUELO00139','CQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 139','Descripcion paquete 139',12,817,937,1077,'emp04','VUELO00139','VUELO00140','CRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 140','Descripcion paquete 140',3,820,940,1080,'emp05','VUELO00140','VUELO00141','AAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 141','Descripcion paquete 141',4,823,943,1083,'emp06','VUELO00141','VUELO00142','ABAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 142','Descripcion paquete 142',5,826,946,1086,'emp07','VUELO00142','VUELO00143','ACAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 143','Descripcion paquete 143',6,829,949,1089,'emp08','VUELO00143','VUELO00144','ADAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 144','Descripcion paquete 144',7,832,952,1092,'emp09','VUELO00144','VUELO00145','AEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 145','Descripcion paquete 145',8,835,955,1095,'emp10','VUELO00145','VUELO00146','AFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 146','Descripcion paquete 146',9,838,958,1098,'emp11','VUELO00146','VUELO00147','AGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 147','Descripcion paquete 147',10,841,961,1101,'emp12','VUELO00147','VUELO00148','AHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 148','Descripcion paquete 148',11,844,964,1104,'emp13','VUELO00148','VUELO00149','AIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 149','Descripcion paquete 149',12,847,967,1107,'emp14','VUELO00149','VUELO00150','AJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 150','Descripcion paquete 150',3,850,970,1110,'emp15','VUELO00150','VUELO00151','AKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 151','Descripcion paquete 151',4,853,973,1113,'emp01','VUELO00151','VUELO00152','ALAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 152','Descripcion paquete 152',5,856,976,1116,'emp02','VUELO00152','VUELO00153','AMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 153','Descripcion paquete 153',6,859,979,1119,'emp03','VUELO00153','VUELO00154','ANAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 154','Descripcion paquete 154',7,862,982,1122,'emp04','VUELO00154','VUELO00155','AOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 155','Descripcion paquete 155',8,865,985,1125,'emp05','VUELO00155','VUELO00156','APAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 156','Descripcion paquete 156',9,868,988,1128,'emp06','VUELO00156','VUELO00157','AQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 157','Descripcion paquete 157',10,871,991,1131,'emp07','VUELO00157','VUELO00158','ARAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 158','Descripcion paquete 158',11,874,994,1134,'emp08','VUELO00158','VUELO00159','ASAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 159','Descripcion paquete 159',12,877,997,1137,'emp09','VUELO00159','VUELO00160','ATAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 160','Descripcion paquete 160',3,880,1000,1140,'emp10','VUELO00160','VUELO00161','AUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 161','Descripcion paquete 161',4,883,1003,1143,'emp11','VUELO00161','VUELO00162','AVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 162','Descripcion paquete 162',5,886,1006,1146,'emp12','VUELO00162','VUELO00163','AWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 163','Descripcion paquete 163',6,889,1009,1149,'emp13','VUELO00163','VUELO00164','AXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 164','Descripcion paquete 164',7,892,1012,1152,'emp14','VUELO00164','VUELO00165','AYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 165','Descripcion paquete 165',8,895,1015,1155,'emp15','VUELO00165','VUELO00166','AZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 166','Descripcion paquete 166',9,898,1018,1158,'emp01','VUELO00166','VUELO00167','BAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 167','Descripcion paquete 167',10,901,1021,1161,'emp02','VUELO00167','VUELO00168','BBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 168','Descripcion paquete 168',11,904,1024,1164,'emp03','VUELO00168','VUELO00169','BCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 169','Descripcion paquete 169',12,907,1027,1167,'emp04','VUELO00169','VUELO00170','BDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 170','Descripcion paquete 170',3,910,1030,1170,'emp05','VUELO00170','VUELO00171','BEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 171','Descripcion paquete 171',4,913,1033,1173,'emp06','VUELO00171','VUELO00172','BFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 172','Descripcion paquete 172',5,916,1036,1176,'emp07','VUELO00172','VUELO00173','BGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 173','Descripcion paquete 173',6,919,1039,1179,'emp08','VUELO00173','VUELO00174','BHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 174','Descripcion paquete 174',7,922,1042,1182,'emp09','VUELO00174','VUELO00175','BIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 175','Descripcion paquete 175',8,925,1045,1185,'emp10','VUELO00175','VUELO00176','BJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 176','Descripcion paquete 176',9,928,1048,1188,'emp11','VUELO00176','VUELO00177','BKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 177','Descripcion paquete 177',10,931,1051,1191,'emp12','VUELO00177','VUELO00178','BLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 178','Descripcion paquete 178',11,934,1054,1194,'emp13','VUELO00178','VUELO00179','BMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 179','Descripcion paquete 179',12,937,1057,1197,'emp14','VUELO00179','VUELO00180','BNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 180','Descripcion paquete 180',3,940,1060,1200,'emp15','VUELO00180','VUELO00181','BOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 181','Descripcion paquete 181',4,943,1063,1203,'emp01','VUELO00181','VUELO00182','BPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 182','Descripcion paquete 182',5,946,1066,1206,'emp02','VUELO00182','VUELO00183','BQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 183','Descripcion paquete 183',6,949,1069,1209,'emp03','VUELO00183','VUELO00184','BRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 184','Descripcion paquete 184',7,952,1072,1212,'emp04','VUELO00184','VUELO00185','BSAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 185','Descripcion paquete 185',8,955,1075,1215,'emp05','VUELO00185','VUELO00186','BTAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 186','Descripcion paquete 186',9,958,1078,1218,'emp06','VUELO00186','VUELO00187','BUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 187','Descripcion paquete 187',10,961,1081,1221,'emp07','VUELO00187','VUELO00188','BVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 188','Descripcion paquete 188',11,964,1084,1224,'emp08','VUELO00188','VUELO00189','BWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 189','Descripcion paquete 189',12,967,1087,1227,'emp09','VUELO00189','VUELO00190','BXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 190','Descripcion paquete 190',3,970,1090,1230,'emp10','VUELO00190','VUELO00191','BYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 191','Descripcion paquete 191',4,973,1093,1233,'emp11','VUELO00191','VUELO00192','BZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 192','Descripcion paquete 192',5,976,1096,1236,'emp12','VUELO00192','VUELO00193','CAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 193','Descripcion paquete 193',6,979,1099,1239,'emp13','VUELO00193','VUELO00194','CBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 194','Descripcion paquete 194',7,982,1102,1242,'emp14','VUELO00194','VUELO00195','CCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 195','Descripcion paquete 195',8,985,1105,1245,'emp15','VUELO00195','VUELO00196','CDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 196','Descripcion paquete 196',9,988,1108,1248,'emp01','VUELO00196','VUELO00197','CEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 197','Descripcion paquete 197',10,991,1111,1251,'emp02','VUELO00197','VUELO00198','CFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 198','Descripcion paquete 198',11,994,1114,1254,'emp03','VUELO00198','VUELO00199','CGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 199','Descripcion paquete 199',12,997,1117,1257,'emp04','VUELO00199','VUELO00200','CHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 200','Descripcion paquete 200',3,1000,1120,1260,'emp05','VUELO00200','VUELO00201','CIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 201','Descripcion paquete 201',4,1003,1123,1263,'emp06','VUELO00201','VUELO00202','CJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 202','Descripcion paquete 202',5,1006,1126,1266,'emp07','VUELO00202','VUELO00203','CKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 203','Descripcion paquete 203',6,1009,1129,1269,'emp08','VUELO00203','VUELO00204','CLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 204','Descripcion paquete 204',7,1012,1132,1272,'emp09','VUELO00204','VUELO00205','CMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 205','Descripcion paquete 205',8,1015,1135,1275,'emp10','VUELO00205','VUELO00206','CNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 206','Descripcion paquete 206',9,1018,1138,1278,'emp11','VUELO00206','VUELO00207','COAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 207','Descripcion paquete 207',10,1021,1141,1281,'emp12','VUELO00207','VUELO00208','CPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 208','Descripcion paquete 208',11,1024,1144,1284,'emp13','VUELO00208','VUELO00209','CQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 209','Descripcion paquete 209',12,1027,1147,1287,'emp14','VUELO00209','VUELO00210','CRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 210','Descripcion paquete 210',3,1030,1150,1290,'emp15','VUELO00210','VUELO00211','AAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 211','Descripcion paquete 211',4,1033,1153,1293,'emp01','VUELO00211','VUELO00212','ABAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 212','Descripcion paquete 212',5,1036,1156,1296,'emp02','VUELO00212','VUELO00213','ACAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 213','Descripcion paquete 213',6,1039,1159,1299,'emp03','VUELO00213','VUELO00214','ADAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 214','Descripcion paquete 214',7,1042,1162,1302,'emp04','VUELO00214','VUELO00215','AEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 215','Descripcion paquete 215',8,1045,1165,1305,'emp05','VUELO00215','VUELO00216','AFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 216','Descripcion paquete 216',9,1048,1168,1308,'emp06','VUELO00216','VUELO00217','AGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 217','Descripcion paquete 217',10,1051,1171,1311,'emp07','VUELO00217','VUELO00218','AHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 218','Descripcion paquete 218',11,1054,1174,1314,'emp08','VUELO00218','VUELO00219','AIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 219','Descripcion paquete 219',12,1057,1177,1317,'emp09','VUELO00219','VUELO00220','AJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 220','Descripcion paquete 220',3,1060,1180,1320,'emp10','VUELO00220','VUELO00221','AKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 221','Descripcion paquete 221',4,1063,1183,1323,'emp11','VUELO00221','VUELO00222','ALAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 222','Descripcion paquete 222',5,1066,1186,1326,'emp12','VUELO00222','VUELO00223','AMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 223','Descripcion paquete 223',6,1069,1189,1329,'emp13','VUELO00223','VUELO00224','ANAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 224','Descripcion paquete 224',7,1072,1192,1332,'emp14','VUELO00224','VUELO00225','AOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 225','Descripcion paquete 225',8,1075,1195,1335,'emp15','VUELO00225','VUELO00226','APAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 226','Descripcion paquete 226',9,1078,1198,1338,'emp01','VUELO00226','VUELO00227','AQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 227','Descripcion paquete 227',10,1081,1201,1341,'emp02','VUELO00227','VUELO00228','ARAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 228','Descripcion paquete 228',11,1084,1204,1344,'emp03','VUELO00228','VUELO00229','ASAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 229','Descripcion paquete 229',12,1087,1207,1347,'emp04','VUELO00229','VUELO00230','ATAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 230','Descripcion paquete 230',3,1090,1210,1350,'emp05','VUELO00230','VUELO00231','AUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 231','Descripcion paquete 231',4,1093,1213,1353,'emp06','VUELO00231','VUELO00232','AVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 232','Descripcion paquete 232',5,1096,1216,1356,'emp07','VUELO00232','VUELO00233','AWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 233','Descripcion paquete 233',6,1099,1219,1359,'emp08','VUELO00233','VUELO00234','AXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 234','Descripcion paquete 234',7,1102,1222,1362,'emp09','VUELO00234','VUELO00235','AYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 235','Descripcion paquete 235',8,1105,1225,1365,'emp10','VUELO00235','VUELO00236','AZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 236','Descripcion paquete 236',9,1108,1228,1368,'emp11','VUELO00236','VUELO00237','BAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 237','Descripcion paquete 237',10,1111,1231,1371,'emp12','VUELO00237','VUELO00238','BBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 238','Descripcion paquete 238',11,1114,1234,1374,'emp13','VUELO00238','VUELO00239','BCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 239','Descripcion paquete 239',12,1117,1237,1377,'emp14','VUELO00239','VUELO00240','BDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 240','Descripcion paquete 240',3,1120,1240,1380,'emp15','VUELO00240','VUELO00241','BEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 241','Descripcion paquete 241',4,1123,1243,1383,'emp01','VUELO00241','VUELO00242','BFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 242','Descripcion paquete 242',5,1126,1246,1386,'emp02','VUELO00242','VUELO00243','BGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 243','Descripcion paquete 243',6,1129,1249,1389,'emp03','VUELO00243','VUELO00244','BHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 244','Descripcion paquete 244',7,1132,1252,1392,'emp04','VUELO00244','VUELO00245','BIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 245','Descripcion paquete 245',8,1135,1255,1395,'emp05','VUELO00245','VUELO00246','BJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 246','Descripcion paquete 246',9,1138,1258,1398,'emp06','VUELO00246','VUELO00247','BKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 247','Descripcion paquete 247',10,1141,1261,1401,'emp07','VUELO00247','VUELO00248','BLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 248','Descripcion paquete 248',11,1144,1264,1404,'emp08','VUELO00248','VUELO00249','BMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 249','Descripcion paquete 249',12,1147,1267,1407,'emp09','VUELO00249','VUELO00250','BNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 250','Descripcion paquete 250',3,1150,1270,1410,'emp10','VUELO00250','VUELO00251','BOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 251','Descripcion paquete 251',4,1153,1273,1413,'emp11','VUELO00251','VUELO00252','BPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 252','Descripcion paquete 252',5,1156,1276,1416,'emp12','VUELO00252','VUELO00253','BQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 253','Descripcion paquete 253',6,1159,1279,1419,'emp13','VUELO00253','VUELO00254','BRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 254','Descripcion paquete 254',7,1162,1282,1422,'emp14','VUELO00254','VUELO00255','BSAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 255','Descripcion paquete 255',8,1165,1285,1425,'emp15','VUELO00255','VUELO00256','BTAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 256','Descripcion paquete 256',9,1168,1288,1428,'emp01','VUELO00256','VUELO00257','BUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 257','Descripcion paquete 257',10,1171,1291,1431,'emp02','VUELO00257','VUELO00258','BVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 258','Descripcion paquete 258',11,1174,1294,1434,'emp03','VUELO00258','VUELO00259','BWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 259','Descripcion paquete 259',12,1177,1297,1437,'emp04','VUELO00259','VUELO00260','BXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 260','Descripcion paquete 260',3,1180,1300,1440,'emp05','VUELO00260','VUELO00261','BYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 261','Descripcion paquete 261',4,1183,1303,1443,'emp06','VUELO00261','VUELO00262','BZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 262','Descripcion paquete 262',5,1186,1306,1446,'emp07','VUELO00262','VUELO00263','CAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 263','Descripcion paquete 263',6,1189,1309,1449,'emp08','VUELO00263','VUELO00264','CBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 264','Descripcion paquete 264',7,1192,1312,1452,'emp09','VUELO00264','VUELO00265','CCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 265','Descripcion paquete 265',8,1195,1315,1455,'emp10','VUELO00265','VUELO00266','CDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 266','Descripcion paquete 266',9,1198,1318,1458,'emp11','VUELO00266','VUELO00267','CEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 267','Descripcion paquete 267',10,1201,1321,1461,'emp12','VUELO00267','VUELO00268','CFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 268','Descripcion paquete 268',11,1204,1324,1464,'emp13','VUELO00268','VUELO00269','CGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 269','Descripcion paquete 269',12,1207,1327,1467,'emp14','VUELO00269','VUELO00270','CHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 270','Descripcion paquete 270',3,1210,1330,1470,'emp15','VUELO00270','VUELO00271','CIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 271','Descripcion paquete 271',4,1213,1333,1473,'emp01','VUELO00271','VUELO00272','CJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 272','Descripcion paquete 272',5,1216,1336,1476,'emp02','VUELO00272','VUELO00273','CKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 273','Descripcion paquete 273',6,1219,1339,1479,'emp03','VUELO00273','VUELO00274','CLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 274','Descripcion paquete 274',7,1222,1342,1482,'emp04','VUELO00274','VUELO00275','CMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 275','Descripcion paquete 275',8,1225,1345,1485,'emp05','VUELO00275','VUELO00276','CNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 276','Descripcion paquete 276',9,1228,1348,1488,'emp06','VUELO00276','VUELO00277','COAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 277','Descripcion paquete 277',10,1231,1351,1491,'emp07','VUELO00277','VUELO00278','CPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 278','Descripcion paquete 278',11,1234,1354,1494,'emp08','VUELO00278','VUELO00279','CQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 279','Descripcion paquete 279',12,1237,1357,1497,'emp09','VUELO00279','VUELO00280','CRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 280','Descripcion paquete 280',3,1240,1360,1500,'emp10','VUELO00280','VUELO00281','AAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 281','Descripcion paquete 281',4,1243,1363,1503,'emp11','VUELO00281','VUELO00282','ABAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 282','Descripcion paquete 282',5,1246,1366,1506,'emp12','VUELO00282','VUELO00283','ACAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 283','Descripcion paquete 283',6,1249,1369,1509,'emp13','VUELO00283','VUELO00284','ADAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 284','Descripcion paquete 284',7,1252,1372,1512,'emp14','VUELO00284','VUELO00285','AEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 285','Descripcion paquete 285',8,1255,1375,1515,'emp15','VUELO00285','VUELO00286','AFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 286','Descripcion paquete 286',9,1258,1378,1518,'emp01','VUELO00286','VUELO00287','AGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 287','Descripcion paquete 287',10,1261,1381,1521,'emp02','VUELO00287','VUELO00288','AHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 288','Descripcion paquete 288',11,1264,1384,1524,'emp03','VUELO00288','VUELO00289','AIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 289','Descripcion paquete 289',12,1267,1387,1527,'emp04','VUELO00289','VUELO00290','AJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 290','Descripcion paquete 290',3,1270,1390,1530,'emp05','VUELO00290','VUELO00291','AKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 291','Descripcion paquete 291',4,1273,1393,1533,'emp06','VUELO00291','VUELO00292','ALAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 292','Descripcion paquete 292',5,1276,1396,1536,'emp07','VUELO00292','VUELO00293','AMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 293','Descripcion paquete 293',6,1279,1399,1539,'emp08','VUELO00293','VUELO00294','ANAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 294','Descripcion paquete 294',7,1282,1402,1542,'emp09','VUELO00294','VUELO00295','AOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 295','Descripcion paquete 295',8,1285,1405,1545,'emp10','VUELO00295','VUELO00296','APAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 296','Descripcion paquete 296',9,1288,1408,1548,'emp11','VUELO00296','VUELO00297','AQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 297','Descripcion paquete 297',10,1291,1411,1551,'emp12','VUELO00297','VUELO00298','ARAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 298','Descripcion paquete 298',11,1294,1414,1554,'emp13','VUELO00298','VUELO00299','ASAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 299','Descripcion paquete 299',12,1297,1417,1557,'emp14','VUELO00299','VUELO00300','ATAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 300','Descripcion paquete 300',3,1300,1420,1560,'emp15','VUELO00300','VUELO00301','AUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 301','Descripcion paquete 301',4,1303,1423,1563,'emp01','VUELO00301','VUELO00302','AVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 302','Descripcion paquete 302',5,1306,1426,1566,'emp02','VUELO00302','VUELO00303','AWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 303','Descripcion paquete 303',6,1309,1429,1569,'emp03','VUELO00303','VUELO00304','AXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 304','Descripcion paquete 304',7,1312,1432,1572,'emp04','VUELO00304','VUELO00305','AYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 305','Descripcion paquete 305',8,1315,1435,1575,'emp05','VUELO00305','VUELO00306','AZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 306','Descripcion paquete 306',9,1318,1438,1578,'emp06','VUELO00306','VUELO00307','BAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 307','Descripcion paquete 307',10,1321,1441,1581,'emp07','VUELO00307','VUELO00308','BBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 308','Descripcion paquete 308',11,1324,1444,1584,'emp08','VUELO00308','VUELO00309','BCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 309','Descripcion paquete 309',12,1327,1447,1587,'emp09','VUELO00309','VUELO00310','BDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 310','Descripcion paquete 310',3,1330,1450,1590,'emp10','VUELO00310','VUELO00311','BEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 311','Descripcion paquete 311',4,1333,1453,1593,'emp11','VUELO00311','VUELO00312','BFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 312','Descripcion paquete 312',5,1336,1456,1596,'emp12','VUELO00312','VUELO00313','BGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 313','Descripcion paquete 313',6,1339,1459,1599,'emp13','VUELO00313','VUELO00314','BHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 314','Descripcion paquete 314',7,1342,1462,1602,'emp14','VUELO00314','VUELO00315','BIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 315','Descripcion paquete 315',8,1345,1465,1605,'emp15','VUELO00315','VUELO00316','BJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 316','Descripcion paquete 316',9,1348,1468,1608,'emp01','VUELO00316','VUELO00317','BKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 317','Descripcion paquete 317',10,1351,1471,1611,'emp02','VUELO00317','VUELO00318','BLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 318','Descripcion paquete 318',11,1354,1474,1614,'emp03','VUELO00318','VUELO00319','BMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 319','Descripcion paquete 319',12,1357,1477,1617,'emp04','VUELO00319','VUELO00320','BNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 320','Descripcion paquete 320',3,1360,1480,1620,'emp05','VUELO00320','VUELO00321','BOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 321','Descripcion paquete 321',4,1363,1483,1623,'emp06','VUELO00321','VUELO00322','BPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 322','Descripcion paquete 322',5,1366,1486,1626,'emp07','VUELO00322','VUELO00323','BQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 323','Descripcion paquete 323',6,1369,1489,1629,'emp08','VUELO00323','VUELO00324','BRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 324','Descripcion paquete 324',7,1372,1492,1632,'emp09','VUELO00324','VUELO00325','BSAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 325','Descripcion paquete 325',8,1375,1495,1635,'emp10','VUELO00325','VUELO00326','BTAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 326','Descripcion paquete 326',9,1378,1498,1638,'emp11','VUELO00326','VUELO00327','BUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 327','Descripcion paquete 327',10,1381,1501,1641,'emp12','VUELO00327','VUELO00328','BVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 328','Descripcion paquete 328',11,1384,1504,1644,'emp13','VUELO00328','VUELO00329','BWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 329','Descripcion paquete 329',12,1387,1507,1647,'emp14','VUELO00329','VUELO00330','BXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 330','Descripcion paquete 330',3,1390,1510,1650,'emp15','VUELO00330','VUELO00331','BYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 331','Descripcion paquete 331',4,1393,1513,1653,'emp01','VUELO00331','VUELO00332','BZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 332','Descripcion paquete 332',5,1396,1516,1656,'emp02','VUELO00332','VUELO00333','CAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 333','Descripcion paquete 333',6,1399,1519,1659,'emp03','VUELO00333','VUELO00334','CBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 334','Descripcion paquete 334',7,1402,1522,1662,'emp04','VUELO00334','VUELO00335','CCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 335','Descripcion paquete 335',8,1405,1525,1665,'emp05','VUELO00335','VUELO00336','CDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 336','Descripcion paquete 336',9,1408,1528,1668,'emp06','VUELO00336','VUELO00337','CEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 337','Descripcion paquete 337',10,1411,1531,1671,'emp07','VUELO00337','VUELO00338','CFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 338','Descripcion paquete 338',11,1414,1534,1674,'emp08','VUELO00338','VUELO00339','CGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 339','Descripcion paquete 339',12,1417,1537,1677,'emp09','VUELO00339','VUELO00340','CHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 340','Descripcion paquete 340',3,1420,1540,1680,'emp10','VUELO00340','VUELO00341','CIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 341','Descripcion paquete 341',4,1423,1543,1683,'emp11','VUELO00341','VUELO00342','CJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 342','Descripcion paquete 342',5,1426,1546,1686,'emp12','VUELO00342','VUELO00343','CKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 343','Descripcion paquete 343',6,1429,1549,1689,'emp13','VUELO00343','VUELO00344','CLAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 344','Descripcion paquete 344',7,1432,1552,1692,'emp14','VUELO00344','VUELO00345','CMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 345','Descripcion paquete 345',8,1435,1555,1695,'emp15','VUELO00345','VUELO00346','CNAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 346','Descripcion paquete 346',9,1438,1558,1698,'emp01','VUELO00346','VUELO00347','COAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 347','Descripcion paquete 347',10,1441,1561,1701,'emp02','VUELO00347','VUELO00348','CPAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 348','Descripcion paquete 348',11,1444,1564,1704,'emp03','VUELO00348','VUELO00349','CQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 349','Descripcion paquete 349',12,1447,1567,1707,'emp04','VUELO00349','VUELO00350','CRAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 350','Descripcion paquete 350',3,1450,1570,1710,'emp05','VUELO00350','VUELO00001','AAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 351','Descripcion paquete 351',4,1453,1573,1713,'emp06','VUELO00001','VUELO00002','ABAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 352','Descripcion paquete 352',5,1456,1576,1716,'emp07','VUELO00002','VUELO00003','ACAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 353','Descripcion paquete 353',6,1459,1579,1719,'emp08','VUELO00003','VUELO00004','ADAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 354','Descripcion paquete 354',7,1462,1582,1722,'emp09','VUELO00004','VUELO00005','AEAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 355','Descripcion paquete 355',8,1465,1585,1725,'emp10','VUELO00005','VUELO00006','AFAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 356','Descripcion paquete 356',9,1468,1588,1728,'emp11','VUELO00006','VUELO00007','AGAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 357','Descripcion paquete 357',10,1471,1591,1731,'emp12','VUELO00007','VUELO00008','AHAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 358','Descripcion paquete 358',11,1474,1594,1734,'emp13','VUELO00008','VUELO00009','AIAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 359','Descripcion paquete 359',12,1477,1597,1737,'emp14','VUELO00009','VUELO00010','AJAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 360','Descripcion paquete 360',3,1480,1600,1740,'emp15','VUELO00010','VUELO00011','AKAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 361','Descripcion paquete 361',4,1483,1603,1743,'emp01','VUELO00011','VUELO00012','ALAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 362','Descripcion paquete 362',5,1486,1606,1746,'emp02','VUELO00012','VUELO00013','AMAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 363','Descripcion paquete 363',6,1489,1609,1749,'emp03','VUELO00013','VUELO00014','ANAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 364','Descripcion paquete 364',7,1492,1612,1752,'emp04','VUELO00014','VUELO00015','AOAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 365','Descripcion paquete 365',8,1495,1615,1755,'emp05','VUELO00015','VUELO00016','APAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 366','Descripcion paquete 366',9,1498,1618,1758,'emp06','VUELO00016','VUELO00017','AQAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 367','Descripcion paquete 367',10,1501,1621,1761,'emp07','VUELO00017','VUELO00018','ARAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 368','Descripcion paquete 368',11,1504,1624,1764,'emp08','VUELO00018','VUELO00019','ASAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 369','Descripcion paquete 369',12,1507,1627,1767,'emp09','VUELO00019','VUELO00020','ATAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 370','Descripcion paquete 370',3,1510,1630,1770,'emp10','VUELO00020','VUELO00021','AUAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 371','Descripcion paquete 371',4,1513,1633,1773,'emp11','VUELO00021','VUELO00022','AVAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 372','Descripcion paquete 372',5,1516,1636,1776,'emp12','VUELO00022','VUELO00023','AWAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 373','Descripcion paquete 373',6,1519,1639,1779,'emp13','VUELO00023','VUELO00024','AXAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 374','Descripcion paquete 374',7,1522,1642,1782,'emp14','VUELO00024','VUELO00025','AYAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 375','Descripcion paquete 375',8,1525,1645,1785,'emp15','VUELO00025','VUELO00026','AZAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 376','Descripcion paquete 376',9,1528,1648,1788,'emp01','VUELO00026','VUELO00027','BAAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 377','Descripcion paquete 377',10,1531,1651,1791,'emp02','VUELO00027','VUELO00028','BBAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 378','Descripcion paquete 378',11,1534,1654,1794,'emp03','VUELO00028','VUELO00029','BCAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 379','Descripcion paquete 379',12,1537,1657,1797,'emp04','VUELO00029','VUELO00030','BDAA');
INSERT INTO PaquetesViajes (titulo,descripcion,cantidadDiasP,precioIndividual,precioDosP,precioTresP,empleadoU,vueloIC,vueloVC,estadoPVC) VALUES ('Paquete 380','Descripcion paquete 380',3,1540,1660,1800,'emp05','VUELO00030','VUELO00031','BEAA');

-- INCLUYEN
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAA',1,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAB',2,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAC',3,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAD',4,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAE',5,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAF',6,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAG',7,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAH',8,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAI',9,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAJ',10,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAK',11,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAL',12,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAM',13,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAN',14,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAO',15,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAP',16,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAQ',17,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAR',18,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAS',19,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAT',20,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAU',21,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAV',22,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAW',23,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAX',24,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAY',25,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAZ',26,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBA',27,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBB',28,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBC',29,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBD',30,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBE',31,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBF',32,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBG',33,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBH',34,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBI',35,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBJ',36,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBK',37,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBL',38,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBM',39,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBN',40,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBO',41,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBP',42,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBQ',43,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBR',44,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBS',45,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBT',46,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBU',47,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBV',48,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBW',49,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBX',50,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBY',51,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBZ',52,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCA',53,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCB',54,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCC',55,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCD',56,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCE',57,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCF',58,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCG',59,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCH',60,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCI',61,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCJ',62,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCK',63,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCL',64,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCM',65,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCN',66,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCO',67,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCP',68,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCQ',69,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCR',70,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCS',71,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCT',72,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCU',73,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCV',74,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCW',75,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCX',76,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCY',77,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCZ',78,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDA',79,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDB',80,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDC',81,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDD',82,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDE',83,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDF',84,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDG',85,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDH',86,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDI',87,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDJ',88,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDK',89,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDL',90,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDM',91,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDN',92,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDO',93,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDP',94,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDQ',95,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDR',96,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDS',97,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDT',98,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDU',99,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDV',100,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDW',101,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDX',102,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDY',103,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDZ',104,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEA',105,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEB',106,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEC',107,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPED',108,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEE',109,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEF',110,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEG',111,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEH',112,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEI',113,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEJ',114,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEK',115,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEL',116,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEM',117,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEN',118,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEO',119,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEP',120,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEQ',121,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPER',122,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPES',123,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPET',124,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEU',125,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEV',126,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEW',127,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEX',128,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEY',129,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEZ',130,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFA',131,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFB',132,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFC',133,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFD',134,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFE',135,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFF',136,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFG',137,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFH',138,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFI',139,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFJ',140,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFK',141,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFL',142,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFM',143,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFN',144,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFO',145,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFP',146,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFQ',147,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFR',148,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFS',149,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFT',150,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFU',151,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFV',152,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFW',153,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFX',154,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFY',155,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFZ',156,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGA',157,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGB',158,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGC',159,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGD',160,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGE',161,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGF',162,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGG',163,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGH',164,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGI',165,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGJ',166,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGK',167,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGL',168,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGM',169,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGN',170,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGO',171,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGP',172,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGQ',173,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGR',174,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGS',175,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGT',176,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGU',177,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGV',178,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGW',179,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGX',180,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGY',181,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGZ',182,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHA',183,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHB',184,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHC',185,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHD',186,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHE',187,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHF',188,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHG',189,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHH',190,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHI',191,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHJ',192,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHK',193,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHL',194,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHM',195,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHN',196,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHO',197,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHP',198,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHQ',199,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHR',200,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHS',201,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHT',201,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHU',202,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHV',202,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHW',203,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHX',203,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHY',204,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHZ',204,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIA',205,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIB',205,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIC',206,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPID',206,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIE',207,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIF',207,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIG',208,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIH',208,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPII',209,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIJ',209,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIK',210,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIL',210,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIM',211,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIN',211,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIO',212,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIP',212,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIQ',213,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIR',213,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIS',214,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIT',214,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIU',215,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIV',215,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIW',216,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIX',216,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIY',217,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIZ',217,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJA',218,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJB',218,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJC',219,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJD',219,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJE',220,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJF',220,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJG',221,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJH',221,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJI',222,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJJ',222,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJK',223,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJL',223,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJM',224,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJN',224,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJO',225,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJP',225,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJQ',226,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJR',226,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJS',227,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJT',227,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJU',228,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJV',228,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJW',229,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJX',229,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJY',230,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJZ',230,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKA',231,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKB',231,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKC',232,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKD',232,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKE',233,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKF',233,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKG',234,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKH',234,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKI',235,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKJ',235,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKK',236,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKL',236,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKM',237,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKN',237,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKO',238,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKP',238,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKQ',239,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKR',239,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKS',240,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKT',240,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKU',241,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKV',241,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKW',242,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKX',242,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKY',243,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKZ',243,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLA',244,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLB',244,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLC',245,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLD',245,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLE',246,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLF',246,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLG',247,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLH',247,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLI',248,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLJ',248,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLK',249,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLL',249,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLM',250,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLN',250,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLO',251,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLP',251,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLQ',252,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLR',252,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLS',253,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLT',253,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLU',254,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLV',254,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLW',255,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLX',255,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLY',256,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLZ',256,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMA',257,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMB',257,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMC',258,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMD',258,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPME',259,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMF',259,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMG',260,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMH',260,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMI',261,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMJ',261,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMK',262,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPML',262,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMM',263,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMN',263,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMO',264,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMP',264,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMQ',265,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMR',265,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMS',266,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMT',266,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMU',267,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMV',267,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMW',268,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMX',268,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMY',269,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMZ',269,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNA',270,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNB',270,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNC',271,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPND',271,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNE',272,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNF',272,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNG',273,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNH',273,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNI',274,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNJ',274,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNK',275,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPNL',275,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAA',276,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAB',276,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAC',277,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAD',277,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAE',278,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAF',278,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAG',279,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAH',279,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAI',280,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAJ',280,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAK',281,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAL',281,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAM',282,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAN',282,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAO',283,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAP',283,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAQ',284,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAR',284,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAS',285,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAT',285,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAU',286,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAV',286,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAW',287,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAX',287,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAY',288,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPAZ',288,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBA',289,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBB',289,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBC',290,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBD',290,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBE',291,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBF',291,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBG',292,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBH',292,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBI',293,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBJ',293,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBK',294,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBL',294,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBM',295,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBN',295,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBO',296,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBP',296,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBQ',297,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBR',297,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBS',298,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBT',298,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBU',299,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBV',299,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBW',300,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBX',300,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBY',301,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPBZ',301,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCA',301,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCB',302,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCC',302,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCD',302,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCE',303,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCF',303,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCG',303,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCH',304,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCI',304,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCJ',304,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCK',305,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCL',305,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCM',305,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCN',306,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCO',306,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCP',306,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCQ',307,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCR',307,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCS',307,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCT',308,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCU',308,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCV',308,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCW',309,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCX',309,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCY',309,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPCZ',310,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDA',310,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDB',310,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDC',311,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDD',311,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDE',311,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDF',312,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDG',312,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDH',312,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDI',313,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDJ',313,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDK',313,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDL',314,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDM',314,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDN',314,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDO',315,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDP',315,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDQ',315,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDR',316,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDS',316,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDT',316,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDU',317,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDV',317,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDW',317,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDX',318,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDY',318,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPDZ',318,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEA',319,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEB',319,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEC',319,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPED',320,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEE',320,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEF',320,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEG',321,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEH',321,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEI',321,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEJ',322,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEK',322,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEL',322,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEM',323,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEN',323,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEO',323,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEP',324,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEQ',324,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPER',324,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPES',325,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPET',325,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEU',325,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEV',326,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEW',326,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEX',326,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEY',327,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPEZ',327,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFA',327,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFB',328,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFC',328,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFD',328,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFE',329,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFF',329,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFG',329,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFH',330,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFI',330,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFJ',330,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFK',331,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFL',331,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFM',331,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFN',332,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFO',332,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFP',332,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFQ',333,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFR',333,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFS',333,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFT',334,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFU',334,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFV',334,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFW',335,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFX',335,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFY',335,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPFZ',336,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGA',336,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGB',336,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGC',337,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGD',337,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGE',337,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGF',338,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGG',338,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGH',338,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGI',339,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGJ',339,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGK',339,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGL',340,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGM',340,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGN',340,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGO',341,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGP',341,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGQ',341,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGR',342,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGS',342,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGT',342,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGU',343,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGV',343,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGW',343,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGX',344,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGY',344,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPGZ',344,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHA',345,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHB',345,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHC',345,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHD',346,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHE',346,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHF',346,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHG',347,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHH',347,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHI',347,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHJ',348,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHK',348,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHL',348,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHM',349,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHN',349,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHO',349,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHP',350,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHQ',350,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHR',350,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHS',351,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHT',351,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHU',351,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHV',351,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHW',352,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHX',352,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHY',352,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPHZ',352,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIA',353,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIB',353,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIC',353,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPID',353,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIE',354,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIF',354,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIG',354,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIH',354,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPII',355,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIJ',355,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIK',355,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIL',355,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIM',356,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIN',356,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIO',356,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIP',356,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIQ',357,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIR',357,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIS',357,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIT',357,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIU',358,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIV',358,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIW',358,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIX',358,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIY',359,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPIZ',359,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJA',359,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJB',359,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJC',360,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJD',360,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJE',360,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJF',360,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJG',361,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJH',361,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJI',361,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJJ',361,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJK',362,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJL',362,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJM',362,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJN',362,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJO',363,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJP',363,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJQ',363,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJR',363,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJS',364,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJT',364,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJU',364,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJV',364,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJW',365,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJX',365,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJY',365,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPJZ',365,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKA',366,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKB',366,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKC',366,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKD',366,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKE',367,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKF',367,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKG',367,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKH',367,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKI',368,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKJ',368,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKK',368,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKL',368,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKM',369,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKN',369,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKO',369,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKP',369,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKQ',370,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKR',370,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKS',370,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKT',370,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKU',371,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKV',371,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKW',371,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKX',371,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKY',372,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPKZ',372,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLA',372,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLB',372,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLC',373,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLD',373,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLE',373,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLF',373,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLG',374,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLH',374,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLI',374,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLJ',374,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLK',375,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLL',375,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLM',375,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLN',375,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLO',376,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLP',376,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLQ',376,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLR',376,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLS',377,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLT',377,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLU',377,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLV',377,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLW',378,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLX',378,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLY',378,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPLZ',378,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMA',379,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMB',379,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMC',379,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMD',379,5);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPME',380,2);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMF',380,3);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMG',380,4);
INSERT INTO Incluyen (codigoH,codigoPV,cantNoches) VALUES ('HOSPMH',380,5);
go

