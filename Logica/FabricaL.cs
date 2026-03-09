using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Logica
{
    public class FabricaL
    {
        public static Interfaces.ILEmpleado GetLogicaEmpleado()
        {
            return (LEmpleado.GetInstancia());
        }

        public static Interfaces.ILEstado GetLogicaEstado()
        {
            return (LEstado.GetInstancia());
        }

        public static Interfaces.ILVuelo GetLogicaVuelo()
        {
            return (LVuelo.GetInstancia());
        }

        public static Interfaces.ILHospedaje GetLogicaHospedaje()
        {
            return (LHospedaje.GetInstancia());
        }

        public static Interfaces.ILPaqueteViaje GetLogicaPaqueteViaje()
        {
            return (LPaqueteViaje.GetInstancia());
        }
    }
}
