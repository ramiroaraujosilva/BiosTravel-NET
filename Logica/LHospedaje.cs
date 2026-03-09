using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Persistencia;
using Entidades_Compartidas;

namespace Logica
{
    internal class LHospedaje : Interfaces.ILHospedaje
    {
        #region Singleton

        // Singleton
        private static LHospedaje _Instancia = null;

        // Constructor por defecto
        private LHospedaje() { }

        // GetInstancia
        public static LHospedaje GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new LHospedaje();

            return _Instancia;
        }

        #endregion

        #region Operaciones

        public void Alta(Hospedajes unHospedaje, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaHospedaje().Alta(unHospedaje, pLogueo);
        }

        public void Eliminar(Hospedajes unHospedaje, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaHospedaje().Eliminar(unHospedaje, pLogueo);
        }

        public void Modificar(Hospedajes unHospedaje, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaHospedaje().Modificar(unHospedaje, pLogueo);
        }

        public Hospedajes Buscar(string pCodigo, Empleados pLogueo)
        {
            return (FabricaP.GetPersistenciaHospedaje().Buscar(pCodigo, pLogueo));
        }

        public List<Hospedajes> Listar(Empleados pLogueo)
        {
            return (FabricaP.GetPersistenciaHospedaje().Listar(pLogueo));
        }        

        #endregion
    }
}
