using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Persistencia;
using Entidades_Compartidas;

namespace Logica
{
    internal class LVuelo : Interfaces.ILVuelo
    {
        #region Singleton

        // Singleton
        private static LVuelo _Instancia = null;

        // Constructor por defecto
        private LVuelo() { }

        // GetInstancia
        public static LVuelo GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new LVuelo();

            return _Instancia;
        }

        #endregion

        #region Operaciones

        public void Alta(Vuelos unVuelo, Empleados pLogueo)
        {
            try
            {
                if (unVuelo.FechaHoraP < unVuelo.FechaHoraL && unVuelo.FechaHoraP > DateTime.Now)
                    FabricaP.GetPersistenciaVuelo().Alta(unVuelo, pLogueo);
                else
                    throw new Exception("Ha ocurrido un error con las fechas, verifique que sean correctas");
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }            
        }

        public void Eliminar(Vuelos unVuelo, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaVuelo().Eliminar(unVuelo, pLogueo);
        }

        public void Modificar(Vuelos unVuelo, Empleados pLogueo)
        {
            try
            {
                if (unVuelo.FechaHoraP < unVuelo.FechaHoraL && unVuelo.FechaHoraP > DateTime.Now)
                    FabricaP.GetPersistenciaVuelo().Modificar(unVuelo, pLogueo);
                else
                    throw new Exception("Ha ocurrido un error con las fechas, verifique que sean correctas");
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public Vuelos Buscar(string pCodigo, Empleados pLogueo)
        {
            return (FabricaP.GetPersistenciaVuelo().Buscar(pCodigo, pLogueo));
        }

        public List<Vuelos> Listar(Empleados pLogueo)
        {
            return (FabricaP.GetPersistenciaVuelo().Listar(pLogueo));
        }
        
        #endregion
    }
}
