using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Persistencia
{
    public class FabricaP
    {
        public static Interfaces.IPEmpleado GetPersistenciaEmpleado()
        {
            return (PEmpleado.GetInstancia());
        }

        public static Interfaces.IPEstado GetPersistenciaEstado()
        {
            return (PEstado.GetInstancia());
        }

        public static Interfaces.IPVuelo GetPersistenciaVuelo()
        {
            return (PVuelo.GetInstancia());
        }

        public static Interfaces.IPHospedaje GetPersistenciaHospedaje()
        {
            return (PHospedaje.GetInstancia());
        }

        public static Interfaces.IPPaqueteViaje GetPersistenciaPaqueteViaje()
        {
            return (PPaqueteViaje.GetInstancia());
        }
    }
}
