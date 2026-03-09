using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;
using Persistencia;

namespace Logica
{
    internal class LEstado : Interfaces.ILEstado
    {
        #region Singleton

        // Singleton
        private static LEstado _Instancia = null;

        // Constructor por defecto
        private LEstado() { }

        // GetInstancia
        public static LEstado GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new LEstado();

            return _Instancia;
        }

        #endregion

        #region Operaciones

        public void Alta(Estados unEstado, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaEstado().Alta(unEstado, pLogueo);
        }

        public void Eliminar(Estados unEstado, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaEstado().Eliminar(unEstado, pLogueo);
        }

        public void Modificar(Estados unEstado, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaEstado().Modificar(unEstado, pLogueo);
        }

        public Estados Buscar(string pCodigo, Empleados pLogueo)
        {
            return FabricaP.GetPersistenciaEstado().Buscar(pCodigo, pLogueo);
        }

        public List<Estados> Listar(Empleados pLogueo)
        {
            return FabricaP.GetPersistenciaEstado().Listar(pLogueo);
        }        

        #endregion
    }
}
