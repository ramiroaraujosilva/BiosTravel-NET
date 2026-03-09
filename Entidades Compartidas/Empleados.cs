using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.ComponentModel;
using System.Text.RegularExpressions;


namespace Entidades_Compartidas
{
    public class Empleados
    {
        // atributos
        private string usuario;
        private string passUsu;
        private string nombreCompleto;

        // propiedades y anotaciones (validación)
        public string Usuario
        {
            get { return usuario; }
            set { usuario = value; }            
        }

        [DisplayName("Contraseña")]
        public string PassUsu
        {
            get { return passUsu; }
            set { passUsu = value; }
        }

        public string NombreCompleto
        {
            get { return nombreCompleto; }
            set { nombreCompleto = value; }
        }

        // constructor completo
        public Empleados(string pUsuario, string pPassUsu, string pNombreCompleto)
        {
            Usuario = pUsuario;
            PassUsu = pPassUsu;
            NombreCompleto = pNombreCompleto;
        }

        // constructor por defecto
        public Empleados() { }

        // operación validar --> código defensivo
        public void Validar()
        {
            if (string.IsNullOrWhiteSpace(this.Usuario) || this.Usuario.Length > 15)
                throw new Exception("El usuario no puede estar vacío, y no puede superar los 15 caracteres");
            if (this.PassUsu.Length < 5 || this.PassUsu.Length > 15)
                throw new Exception("La contraseña no puede tener menos de 5 ni más de 15 caracteres");
            if (!Regex.IsMatch(this.PassUsu, @"^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@%$#&=]).+$"))
                throw new Exception("La contraseña debe contener por lo menos una letra, un número y un caracter especial");
            if (string.IsNullOrWhiteSpace(this.NombreCompleto) || this.NombreCompleto.Length > 40)
                throw new Exception("Nombre completo: no puede estar vacío ni su perar los 40 caracteres");
        }
    }
}
