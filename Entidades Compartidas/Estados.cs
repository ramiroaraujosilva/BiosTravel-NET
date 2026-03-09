using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.ComponentModel;
using System.Text.RegularExpressions;

namespace Entidades_Compartidas
{
    public class Estados
    {
        // atributos
        private string codigo;
        private string nombre;
        private string pais;

        // propiedades
        public string Codigo
        {
            get { return codigo; }
            set { codigo = value; }
        }

        public string Nombre
        {
            get { return nombre; }
            set { nombre = value; }
        }

        public string Pais
        {
            get { return pais; }
            set { pais = value; }
        }

        // constructor completo
        public Estados(string pCodigo, string pNombre, string pPais)
        {
            Codigo = pCodigo;
            Nombre = pNombre;
            Pais = pPais;
        }

        // constructor por defecto
        public Estados() { }

        // operación validar --> código defensivo
        public void Validar()
        {
            if (!Regex.IsMatch(this.Codigo, @"^[a-zA-Z]{4}$"))
                throw new Exception("El código del Estado debe estar compuesto por 4 letras");
            if (string.IsNullOrWhiteSpace(this.Nombre))
                throw new Exception("Debe ingresar el Nombre del Estado");
            if (this.Nombre.Trim().Length > 25)
                throw new Exception("El nombre no puede superar los 25 caracteres");
            if (string.IsNullOrWhiteSpace(this.Pais))
                throw new Exception("Debe ingresar el País al cual pertenece el Estado");
            if (this.Pais.Trim().Length > 25)
                throw new Exception("El país no puede superar los 25 caracteres");
        }
    }
}
