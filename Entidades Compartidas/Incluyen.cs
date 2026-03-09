using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.ComponentModel;

namespace Entidades_Compartidas
{
    public class Incluyen
    {
        // atributos
        private int cantNoches;
        private Hospedajes hospedaje;

        // propiedades
        [DisplayName("Cantidad de noches")]
        public int CantNoches
        {
            get { return cantNoches; }
            set { cantNoches = value; }
        }

        public Hospedajes Hospedaje
        {
            get { return hospedaje; }
            set { hospedaje = value; }
        }

        // constructor completo
        public Incluyen(int pCantNoches, Hospedajes pHospedaje) 
        {
            CantNoches = pCantNoches;
            Hospedaje = pHospedaje;            
        }

        // constructor por defecto
        public Incluyen() { }

        // operación validar --> código defensivo
        public void Validar()
        {
            if (this.CantNoches <= 0 || this.CantNoches > 100)
                throw new Exception("La cantidad de noches por hospedaje debe ser entre 1 y 100");
            if (this.Hospedaje == null)
                throw new Exception("Debe seleccionar el hospedaje");        
        }
    }
}
