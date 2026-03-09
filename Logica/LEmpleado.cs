using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;
using Persistencia;


namespace Logica
{
    internal class LEmpleado : Interfaces.ILEmpleado
    {
        #region Singleton

        // Singleton
        private static LEmpleado _Instancia = null;

        // Constructor por defecto
        private LEmpleado() { }

        // GetInstancia
        public static LEmpleado GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new LEmpleado();

            return _Instancia;
        }
        #endregion

        #region Operaciones

        public void NuevoUsuario(Empleados unEmpleado, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaEmpleado().NuevoUsuario(unEmpleado, pLogueo);
        }

        public void Modificar(Empleados unEmpleado, Empleados pLogueo)
        {
            FabricaP.GetPersistenciaEmpleado().Modificar(unEmpleado, pLogueo);
        }

        public Empleados Logueo(string pUsuario, string pPassUsu)
        {
            return FabricaP.GetPersistenciaEmpleado().Logueo(pUsuario, pPassUsu);
        }

        public Empleados Buscar(string pUsuario, Empleados pLogueo)
        {
            return FabricaP.GetPersistenciaEmpleado().Buscar(pUsuario, pLogueo);
        }

        public List<Empleados> Listar(Empleados pLogueo)
        {
            return FabricaP.GetPersistenciaEmpleado().Listar(pLogueo);
        }

        #endregion
    }
}
